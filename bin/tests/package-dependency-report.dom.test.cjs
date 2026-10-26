const { createHash } = require('node:crypto');
const { createInteractiveReport } = require('../package-dependency-report');

function graph(directory) {
    const node = (name, children = [], status = 'OK', selected = null) => ({
        name,
        version: '1.0.0.1',
        status,
        children,
        selected
    });
    return {
        directory,
        roots: ['app', 'parent'],
        nodes: new Map([
            ['app', node('example-app', ['parent', 'missing'])],
            ['parent', node('example-parent', ['shared', 'older'])],
            ['shared', node('shared-library')],
            ['missing', node('missing-library', [], 'MISSING')],
            ['older', node('shared-library', [], 'VERSION DIFF', '2.0.0.1')],
            ['unrelated', node('unrelated-library')]
        ])
    };
}

function openReport(graphs = [graph('force-app')]) {
    const html = createInteractiveReport(graphs, 'synthetic-project.json');
    const parsed = new DOMParser().parseFromString(html, 'text/html');
    document.body.replaceChildren(...parsed.body.childNodes);
    const script = document.querySelector('script').textContent;
    window.eval(script);
    return { html, script, section: document.querySelector('.graph') };
}

function node(section, name) {
    return [...section.querySelectorAll('.node')].find((element) =>
        element.getAttribute('aria-label').startsWith(name)
    );
}

afterEach(() => document.body.replaceChildren());

test('hover traces only direct incoming/outgoing arrows, preserves directions and dims unrelated nodes', () => {
    const { section } = openReport();
    const parent = node(section, 'example-parent');
    parent.dispatchEvent(new Event('pointerenter'));
    expect(parent.classList.contains('active')).toBe(true);
    expect(section.querySelectorAll('.edge.outgoing')).toHaveLength(2);
    expect(section.querySelectorAll('.edge.incoming')).toHaveLength(1);
    expect(section.querySelectorAll('.edge.dimmed')).toHaveLength(1);
    expect(node(section, 'unrelated-library').classList.contains('dimmed')).toBe(true);
    expect(node(section, 'example-app').classList.contains('dimmed')).toBe(false);
    expect(section.querySelector('.edge.outgoing').getAttribute('marker-end')).toBe('url(#graph0-outgoing)');
    expect(section.querySelector('.edge.incoming').getAttribute('marker-end')).toBe('url(#graph0-incoming)');
    expect(section.querySelector('.details').textContent).toContain('Subscriber version ID: parent');
    expect(section.querySelector('.details').textContent).toContain('Requires (outgoing');
    expect(section.querySelector('.details').textContent).toContain('Required by (incoming');
    parent.dispatchEvent(new Event('pointerleave'));
    expect(section.querySelectorAll('.dimmed')).toHaveLength(0);
    expect(section.querySelectorAll('.active')).toHaveLength(0);
});

test('click pins the selection across hover, and clear or Escape releases it', () => {
    const { section } = openReport();
    const parent = node(section, 'example-parent');
    parent.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    parent.dispatchEvent(new Event('pointerleave'));
    node(section, 'missing-library').dispatchEvent(new Event('pointerenter'));
    expect(parent.getAttribute('aria-pressed')).toBe('true');
    expect(parent.classList.contains('active')).toBe(true);
    expect(section.querySelector('.details').textContent).toContain('Selection locked');
    section.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    expect(section.querySelectorAll('.active')).toHaveLength(0);
    parent.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    parent.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    expect(parent.getAttribute('aria-pressed')).toBe('false');
    section.querySelector('[data-action="clear"]').click();
    expect(section.querySelectorAll('.dimmed')).toHaveLength(0);
});

test('keyboard focus previews, Enter/Space pins and the selector navigates without a mouse', () => {
    const { section } = openReport();
    const parent = node(section, 'example-parent');
    parent.focus();
    expect(parent.classList.contains('active')).toBe(true);
    parent.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
    expect(parent.getAttribute('aria-pressed')).toBe('true');
    parent.dispatchEvent(new KeyboardEvent('keydown', { key: ' ', bubbles: true }));
    expect(parent.getAttribute('aria-pressed')).toBe('false');
    const select = section.querySelector('select');
    select.value = node(section, 'missing-library').dataset.key;
    select.dispatchEvent(new Event('change'));
    expect(node(section, 'missing-library').getAttribute('aria-pressed')).toBe('true');
    const link = [...section.querySelectorAll('.details button')].find((button) =>
        button.textContent.startsWith('example-app')
    );
    link.click();
    expect(node(section, 'example-app').getAttribute('aria-pressed')).toBe('true');
});

test('below-minimum versions are not expanded as if they met the requirement', () => {
    const { section } = openReport();
    const conflict = section.querySelector('[data-status="VERSION DIFF"]');
    conflict.dispatchEvent(new Event('pointerenter'));
    expect(section.querySelector('.details').textContent).toContain(
        'Not expanded: selected version is below the required minimum.'
    );
    expect(section.querySelector('.details').textContent).toContain('selected 2.0.0.1');
});

test('higher selected versions expose their minimum in the accessible graph node', () => {
    const fixture = graph('force-app');
    fixture.roots.push('higher');
    fixture.nodes.set('higher', {
        name: 'newer-library',
        version: '2.0.0.1',
        status: 'HIGHER',
        requirements: [{ minimum: '1.0.0.1', requiredBy: 'example-parent 1.0.0.1' }],
        children: []
    });
    const { section } = openReport([fixture]);
    const higher = section.querySelector('[data-version-id="higher"]');
    expect(higher.classList.contains('ok')).toBe(true);
    expect(higher.getAttribute('aria-label')).toContain('minimum 1.0.0.1');
    expect(higher.textContent).toContain('minimum 1.0.0.1');
});

test('zoom, fit and keyboard pan update the view without modifying graph connections', () => {
    const { section } = openReport();
    const svg = section.querySelector('svg');
    const initial = svg.getAttribute('viewBox');
    const initialWidth = Number(initial.split(' ')[2]);
    section.querySelector('[data-action="in"]').click();
    expect(Number(svg.getAttribute('viewBox').split(' ')[2])).toBeLessThan(initialWidth);
    section.querySelector('[data-action="out"]').click();
    expect(Number(svg.getAttribute('viewBox').split(' ')[2])).toBeCloseTo(initialWidth);
    svg.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }));
    expect(Number(svg.getAttribute('viewBox').split(' ')[0])).toBeGreaterThan(0);
    svg.dispatchEvent(new WheelEvent('wheel', { deltaY: -1, cancelable: true }));
    expect(Number(svg.getAttribute('viewBox').split(' ')[2])).toBeLessThan(initialWidth);
    section.querySelector('[data-action="fit"]').click();
    expect(svg.getAttribute('viewBox')).toBe(initial);
    expect(section.querySelectorAll('.node')).toHaveLength(6);
    expect(section.querySelectorAll('.edge')).toHaveLength(4);
});

test('separate directory graphs have unique markers and independent selections', () => {
    const { section } = openReport([graph('force-app'), graph('second-directory')]);
    node(section, 'example-parent').dispatchEvent(new MouseEvent('click', { bubbles: true }));
    const second = document.querySelectorAll('.graph')[1];
    expect(second.querySelectorAll('.dimmed')).toHaveLength(0);
    node(second, 'example-app').dispatchEvent(new MouseEvent('click', { bubbles: true }));
    expect(section.querySelector('.active').getAttribute('aria-label')).toContain('example-parent');
    expect(second.querySelector('.edge.outgoing').getAttribute('marker-end')).toBe('url(#graph1-outgoing)');
    const ids = [...document.querySelectorAll('[id]')].map((element) => element.id);
    expect(new Set(ids).size).toBe(ids.length);
});

test('script hash matches the offline CSP and untrusted labels stay literal inert text', () => {
    const malicious = graph('directory <img src=x onerror=alert(1)>');
    malicious.nodes.get('app').name = '</script><img src=x onerror=alert(1)>';
    const { html, script, section } = openReport([malicious]);
    const hash = createHash('sha256').update(script).digest('base64');
    expect(html).toContain(`script-src 'sha256-${hash}'`);
    expect(html).toContain("default-src 'none'");
    expect(document.querySelectorAll('img')).toHaveLength(0);
    expect(document.querySelectorAll('script')).toHaveLength(1);
    node(section, '</script>').dispatchEvent(new Event('pointerenter'));
    expect(section.querySelector('.details h3').textContent).toContain('</script><img');
});

test('empty projects remain readable and require no external assets', () => {
    const { html } = openReport([]);
    expect(document.body.textContent).toContain('No package dependencies declared.');
    expect(document.querySelectorAll('script[src],link[href],iframe,img')).toHaveLength(0);
    expect(html).not.toMatch(/\b(?:fetch|XMLHttpRequest|WebSocket)\s*\(/);
});
