const { createHash } = require('node:crypto');

function escapeHtml(value) {
    const entities = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
    return String(value).replace(/[&<>"']/g, (character) => entities[character]);
}

function initializeExplorer() {
    for (const section of document.querySelectorAll('.graph')) {
        const svg = section.querySelector('svg');
        const nodes = [...section.querySelectorAll('.node')];
        const edges = [...section.querySelectorAll('.edge')];
        const details = section.querySelector('.details');
        const selection = section.querySelector('select');
        const initial = svg.getAttribute('viewBox').split(' ').map(Number);
        let view = [...initial];
        let pinned = null;
        let hovered = null;
        let focused = null;
        let drag = null;
        const find = (key) => nodes.find((node) => node.dataset.key === key);
        const name = (node) => node.getAttribute('aria-label');
        const render = () => {
            const active = pinned ?? hovered ?? focused;
            const related = new Set(active ? [active] : []);
            for (const edge of edges) {
                const outgoing = edge.dataset.from === active;
                const incoming = edge.dataset.to === active;
                if (outgoing || incoming) {
                    related.add(edge.dataset.from);
                    related.add(edge.dataset.to);
                }
                const direction = outgoing ? 'outgoing' : incoming ? 'incoming' : 'base';
                edge.classList.toggle('outgoing', outgoing);
                edge.classList.toggle('incoming', incoming);
                edge.classList.toggle('dimmed', active !== null && !outgoing && !incoming);
                edge.setAttribute('marker-end', `url(#${section.id}-${direction})`);
            }
            for (const node of nodes) {
                node.classList.toggle('active', node.dataset.key === active);
                node.classList.toggle('dimmed', active !== null && !related.has(node.dataset.key));
                node.setAttribute('aria-pressed', String(node.dataset.key === pinned));
            }
            selection.value = pinned ?? '';
            details.replaceChildren();
            const title = document.createElement('h3');
            title.textContent = active ? name(find(active)) : 'Connections';
            details.append(title);
            const state = document.createElement('p');
            state.textContent = pinned
                ? 'Selection locked. Click again or Clear selection to unlock.'
                : active
                  ? 'Preview. Click or press Enter to lock this selection.'
                  : 'Hover or focus a node to trace its direct connections.';
            details.append(state);
            if (!active) return;
            const id = document.createElement('p');
            id.textContent = `Subscriber version ID: ${find(active).dataset.versionId}`;
            details.append(id);
            for (const [direction, heading] of [
                ['outgoing', 'Requires (outgoing, solid blue arrows)'],
                ['incoming', 'Required by (incoming, dashed orange arrows)']
            ]) {
                const label = document.createElement('h4');
                label.textContent = heading;
                details.append(label);
                const connections = edges.filter((edge) =>
                    direction === 'outgoing' ? edge.dataset.from === active : edge.dataset.to === active
                );
                if (!connections.length) {
                    const empty = document.createElement('p');
                    empty.textContent =
                        direction === 'outgoing' && find(active).dataset.status === 'VERSION DIFF'
                            ? 'Not expanded: selected version is below the required minimum.'
                            : 'None in the inspected graph.';
                    details.append(empty);
                }
                const list = document.createElement('ul');
                for (const edge of connections) {
                    const key = direction === 'outgoing' ? edge.dataset.to : edge.dataset.from;
                    const item = document.createElement('li');
                    const button = document.createElement('button');
                    button.type = 'button';
                    button.textContent = name(find(key));
                    button.addEventListener('click', () => {
                        pinned = key;
                        render();
                    });
                    item.append(button);
                    list.append(item);
                }
                details.append(list);
            }
        };
        const clear = () => {
            pinned = null;
            hovered = null;
            focused = null;
            render();
        };
        const updateView = () => svg.setAttribute('viewBox', view.join(' '));
        const zoom = (factor) => {
            const width = Math.max(initial[2] / 12, Math.min(initial[2] * 3, view[2] * factor));
            const ratio = width / view[2];
            view = [view[0] + (view[2] - width) / 2, view[1] + (view[3] - view[3] * ratio) / 2, width, view[3] * ratio];
            updateView();
        };
        for (const node of nodes) {
            const key = node.dataset.key;
            node.addEventListener('pointerenter', () => {
                hovered = key;
                render();
            });
            node.addEventListener('pointerleave', () => {
                hovered = null;
                render();
            });
            node.addEventListener('focus', () => {
                focused = key;
                render();
            });
            node.addEventListener('blur', () => {
                focused = null;
                render();
            });
            const toggle = () => {
                pinned = pinned === key ? null : key;
                render();
            };
            node.addEventListener('click', toggle);
            node.addEventListener('keydown', (event) => {
                if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    toggle();
                }
            });
        }
        selection.addEventListener('change', () => {
            pinned = selection.value || null;
            render();
        });
        section.querySelector('[data-action="clear"]').addEventListener('click', clear);
        section.querySelector('[data-action="in"]').addEventListener('click', () => zoom(0.8));
        section.querySelector('[data-action="out"]').addEventListener('click', () => zoom(1.25));
        section.querySelector('[data-action="fit"]').addEventListener('click', () => {
            view = [...initial];
            updateView();
        });
        section.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') clear();
            if (event.target !== svg) return;
            const moves = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] };
            if (moves[event.key]) {
                event.preventDefault();
                view[0] += (moves[event.key][0] * view[2]) / 10;
                view[1] += (moves[event.key][1] * view[3]) / 10;
                updateView();
            }
        });
        svg.addEventListener(
            'wheel',
            (event) => {
                event.preventDefault();
                zoom(event.deltaY > 0 ? 1.1 : 0.9);
            },
            { passive: false }
        );
        svg.addEventListener('pointerdown', (event) => {
            if (event.target.closest('.node') || event.button !== 0) return;
            const matrix = svg.getScreenCTM();
            if (!matrix) return;
            drag = { x: event.clientX, y: event.clientY, view: [...view], scale: matrix.a };
            svg.setPointerCapture(event.pointerId);
        });
        svg.addEventListener('pointermove', (event) => {
            if (!drag) return;
            view = [
                drag.view[0] - (event.clientX - drag.x) / drag.scale,
                drag.view[1] - (event.clientY - drag.y) / drag.scale,
                drag.view[2],
                drag.view[3]
            ];
            updateView();
        });
        svg.addEventListener('pointerup', () => {
            drag = null;
        });
        svg.addEventListener('pointercancel', () => {
            drag = null;
        });
        render();
    }
}

function createInteractiveReport(graphs, projectName) {
    const sections = graphs
        .map((graph, graphIndex) => {
            const id = `graph${graphIndex}`;
            const entries = [...graph.nodes];
            const keys = new Map(entries.map(([versionId], index) => [versionId, `n${index}`]));
            const ranks = new Map();
            const rank = (versionId) => {
                if (!ranks.has(versionId)) {
                    const node = graph.nodes.get(versionId);
                    ranks.set(versionId, node.children.length ? 1 + Math.max(...node.children.map(rank)) : 0);
                }
                return ranks.get(versionId);
            };
            const maximum = Math.max(0, ...entries.map(([versionId]) => rank(versionId)));
            const rows = new Map();
            const positions = new Map(
                entries.map(([versionId]) => {
                    const column = maximum - rank(versionId);
                    const row = rows.get(column) ?? 0;
                    rows.set(column, row + 1);
                    return [versionId, { x: 30 + column * 520, y: 30 + row * 140 }];
                })
            );
            const width = 420 + maximum * 520;
            const height = 70 + Math.max(1, ...rows.values()) * 140;
            const markers = ['base', 'outgoing', 'incoming']
                .map(
                    (tone) =>
                        `<marker id="${id}-${tone}" markerWidth="10" markerHeight="10" refX="9" refY="5" orient="auto"><path d="M0 0 L10 5 L0 10 Z" class="${tone}"/></marker>`
                )
                .join('');
            const edges = entries
                .flatMap(([versionId, node]) =>
                    node.children.map((child) => {
                        const from = positions.get(versionId);
                        const to = positions.get(child);
                        const middle = (from.x + 360 + to.x) / 2;
                        return `<path class="edge" data-from="${keys.get(versionId)}" data-to="${keys.get(child)}" d="M${from.x + 360} ${from.y + 50} C${middle} ${from.y + 50} ${middle} ${to.y + 50} ${to.x} ${to.y + 50}" marker-end="url(#${id}-base)"/>`;
                    })
                )
                .join('\n');
            const nodeDetails = (node) => {
                const minimums = [...new Set((node.requirements ?? []).map((entry) => entry.minimum))];
                return [
                    minimums.length ? `minimum ${minimums.join(', ')}` : '',
                    node.selected ? `selected ${node.selected}` : ''
                ]
                    .filter(Boolean)
                    .join('; ');
            };
            const nodeName = (node) =>
                `${node.name} ${node.version} [${node.status}${nodeDetails(node) ? `; ${nodeDetails(node)}` : ''}]`;
            const nodes = entries
                .map(([versionId, node]) => {
                    const position = positions.get(versionId);
                    const state =
                        node.status === 'OK' || node.status === 'HIGHER'
                            ? 'ok'
                            : node.status === 'MISSING'
                              ? 'missing'
                              : 'conflict';
                    const chunks = node.name.match(/.{1,40}/g) ?? [''];
                    const name = chunks
                        .slice(0, 2)
                        .map((part, index) => `<tspan x="14" y="${24 + index * 19}">${escapeHtml(part)}</tspan>`)
                        .join('');
                    return `<g class="node ${state}" data-key="${keys.get(versionId)}" data-status="${node.status}" data-version-id="${escapeHtml(versionId)}" transform="translate(${position.x} ${position.y})" role="button" tabindex="0" aria-pressed="false" aria-label="${escapeHtml(nodeName(node))}">
<title>${escapeHtml(nodeName(node))}</title><rect width="360" height="100" rx="8"/>
<text class="package-name">${name}</text><text x="14" y="67">${escapeHtml(node.version)} | ${node.status}</text>
${nodeDetails(node) ? `<text x="14" y="87">${escapeHtml(nodeDetails(node))}</text>` : ''}</g>`;
                })
                .join('\n');
            const options = entries
                .map(
                    ([versionId, node]) =>
                        `<option value="${keys.get(versionId)}">${escapeHtml(nodeName(node))}</option>`
                )
                .join('');
            return `<section class="graph" id="${id}" aria-labelledby="${id}-title">
<h2 id="${id}-title">${escapeHtml(graph.directory)}</h2>
<div class="toolbar"><label>Lock a node <select><option value="">No locked selection</option>${options}</select></label>
<button type="button" data-action="clear">Clear selection</button><button type="button" data-action="in">Zoom in</button><button type="button" data-action="out">Zoom out</button><button type="button" data-action="fit">Fit graph</button></div>
<div class="explorer"><svg viewBox="0 0 ${width} ${height}" tabindex="0" role="group" aria-label="${escapeHtml(graph.directory)} dependency graph; arrow keys pan"><defs>${markers}</defs>${edges}${nodes}</svg>
<aside class="details" aria-label="Selected node connections" aria-live="polite"><h3>Connections</h3><p>Enable JavaScript for interactive tracing.</p></aside></div></section>`;
        })
        .join('\n');
    const script = `(${initializeExplorer.toString()})();`;
    const hash = createHash('sha256').update(script).digest('base64');
    return `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'sha256-${hash}'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Dependency graph explorer</title>
<style>
* { box-sizing: border-box; } body { margin: 0; padding: 24px; background: #f1f5f9; color: #0f172a; font: 16px/1.5 system-ui, sans-serif; }
h1,h2,h3,h4 { line-height: 1.3; } h1 { margin-top: 0; } .graph { background: #fff; border: 1px solid #94a3b8; border-radius: 10px; padding: 20px; margin: 24px 0; }
.toolbar { display: flex; gap: 10px; align-items: end; flex-wrap: wrap; margin-bottom: 16px; } label { display: grid; max-width: 100%; }
button,select { font: inherit; padding: 8px 12px; border: 1px solid #64748b; border-radius: 4px; background: white; color: #0f172a; }
button { cursor: pointer; } select { max-width: 38rem; width: 100%; } :focus-visible { outline: 3px solid #1d4ed8; outline-offset: 3px; }
.explorer { display: grid; grid-template-columns: minmax(0,1fr) minmax(260px,340px); gap: 20px; }
svg { display: block; width: 100%; height: 70vh; min-height: 420px; border: 1px solid #94a3b8; background: #f8fafc; touch-action: none; cursor: grab; }
.details { max-height: 70vh; overflow: auto; overflow-wrap: anywhere; padding: 0 8px; } .details h3 { margin-top: 0; } .details li { margin: 8px 0; } .details button { text-align: left; font-size: 14px; }
.node { cursor: pointer; } .node rect { stroke-width: 1.5; } .node.ok rect { fill: #dcfce7; stroke: #166534; } .node.missing rect { fill: #fee2e2; stroke: #991b1b; } .node.conflict rect { fill: #fef3c7; stroke: #92400e; }
.node text { fill: #0f172a; font: 14px system-ui, sans-serif; } .node .package-name { font-weight: 650; } .node.active rect, .node:focus-visible rect { stroke: #1d4ed8; stroke-width: 4; }
.edge { fill: none; stroke: #64748b; stroke-width: 1.5; } .edge.outgoing { stroke: #1d4ed8; stroke-width: 3; } .edge.incoming { stroke: #b45309; stroke-width: 3; stroke-dasharray: 8 4; }
marker .base { fill: #64748b; } marker .outgoing { fill: #1d4ed8; } marker .incoming { fill: #b45309; } .dimmed { opacity: .15; }
.outgoing-key { color: #1d4ed8; font-weight: 600; } .incoming-key { color: #92400e; font-weight: 600; }
@media (max-width: 800px) { body { padding: 12px; } .explorer { grid-template-columns: 1fr; } .details { max-height: none; } }
</style></head><body>
<h1>Dependency graph explorer</h1><p>Project: ${escapeHtml(projectName)} | Generated: ${new Date().toISOString()}</p>
<p>Hover or focus a node to highlight its direct connections. Click, Enter or Space locks a selection; Escape clears it. Use the node selector for keyboard navigation.</p>
<p><span class="outgoing-key">Requires (outgoing, solid blue)</span> | <span class="incoming-key">Required by (incoming, dashed orange)</span>. Unrelated nodes and arrows fade. Scroll to zoom; drag the background to pan, or focus the graph and use arrow keys.</p>
<p>Node status: OK (green, equal minimum), HIGHER (green, selected version exceeds minimum), MISSING (red), VERSION DIFF (yellow, selected version below minimum). Versions are compared numerically as minimum requirements; higher selected versions satisfy lower requirements. The selected versions' dependency graph is inspected. This is the inspected manifest graph, not installed org state.</p>
<noscript><p>JavaScript is disabled. Static graphs remain available; use the Markdown report for findings and inventories.</p></noscript>
${sections || '<p>No package dependencies declared.</p>'}
<script>${script}</script></body></html>
`;
}

module.exports = { createInteractiveReport };
