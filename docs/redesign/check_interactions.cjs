// Dependency-free behavioral check for the preview only: node check_interactions.cjs.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const source = fs.readFileSync(`${__dirname}/preview.html`, 'utf8');
const elements = new Map();
function element(id) {
  if (!elements.has(id)) elements.set(id, {
    value: '', textContent: '', hidden: false, disabled: false, dataset: {},
    attributes: {}, classes: new Set(), classList: { toggle() {}, add(c) { element(id).classes.add(c); }, remove(c) { element(id).classes.delete(c); } }, style: { setProperty() {} },
    listeners: {}, addEventListener(type, callback) { this.listeners[type] = callback; }, setAttribute(k, v) { this.attributes[k] = v; },
    removeAttribute(k) { delete this.attributes[k]; }, scrollIntoView() {},
    focus() {}, querySelector() { return element(`${id}-scroller`); },
    showModal() { this.open = true; this.openCount = (this.openCount || 0) + 1; }, close() { this.open = false; },
  });
  return elements.get(id);
}
const timers = [];
const context = vm.createContext({
  document: { getElementById: element, querySelectorAll: () => [],
    addEventListener() {}, body: element('body') },
  window: { matchMedia: () => ({matches:false}) }, Intl, setTimeout: callback => timers.push(callback),
});
element('theme').value = 'forui';
element('width').value = '360';
element('scale').value = '1';
element('category').value = 'Semua kategori';
vm.runInContext(source.split('<script>')[1].split('</script>')[0], context);
assert.equal(element('total').textContent, 'Rp11.000');
element('search').value = 'biskuit';
vm.runInContext('render()', context);
assert.match(element('products').innerHTML, /Biskuit kelapa/);
assert.doesNotMatch(element('products').innerHTML, /Mi instan goreng/);
assert.equal(element('total').textContent, 'Rp11.000', 'Search must retain selection');
element('saveResult').value = 'error';
element('save').onclick();
element('save').onclick();
assert.equal(timers.length, 1, 'Double save must be blocked');
assert.equal(element('save').disabled, true);
assert.equal(element('sale-scroller').inert, true);
element('saveResult').value = 'success';
timers.shift()();
assert.match(element('saleNotice').textContent, /Belum tersimpan/,
  'Result must be captured when saving starts');
assert.equal(element('total').textContent, 'Rp11.000');
assert.equal(element('sale-scroller').inert, false);
assert.ok(!element('successDialog').open, 'Failure must not show success animation');
element('soundToggle').onclick(); // Mute before success: no audio device required.
assert.equal(element('soundToggle').attributes['aria-checked'], 'false');
element('soundTest').onclick();
assert.match(element('audioStatus').textContent, /dimatikan/);
element('save').onclick();
timers.shift()();
assert.match(element('saleNotice').textContent, /berhasil dicatat/);
assert.equal(element('successDialog').open, true);
assert.equal(element('successAmount').textContent, 'Rp11.000');
element('successClose').onclick();
assert.equal(element('successDialog').open, false);
element('save').onclick(); timers.shift()();
assert.equal(element('successDialog').openCount, 2, 'Success animation can run again');
vm.runInContext('products.forEach(p=>p.qty=0);render()', context);
assert.equal(element('save').disabled, true, 'Empty cart cannot save');
console.log('PASS: selection retention, double-save lock, failure snapshot, success, mute, empty cart');

// Scroll entry animates; partial exit must not reset; full exit allows replay.
let chartCallback;
const chartClasses = new Set();
const chart = { classList: { add: c => chartClasses.add(c), remove: c => chartClasses.delete(c) } };
context.window.IntersectionObserver = class {
  constructor(callback) { chartCallback = callback; }
  observe(target) { assert.equal(target, chart); }
};
context.document.querySelectorAll = selector => selector === '.bar-chart' ? [chart] : [];
vm.runInContext(source.split("if('IntersectionObserver' in window){")[1].split('updateThemeChoices();appearance();render();rank();')[0].replace(/}\s*$/, ''), context);
const enter = (visible, ratio) => chartCallback([{target:chart,isIntersecting:visible,intersectionRatio:ratio}]);
enter(true,.1); assert.equal(chartClasses.has('is-visible'),false);
enter(true,.35); assert.equal(chartClasses.has('is-visible'),true);
enter(true,.1); assert.equal(chartClasses.has('is-visible'),true);
enter(false,0); assert.equal(chartClasses.has('is-visible'),false);
enter(true,.5); assert.equal(chartClasses.has('is-visible'),true);
console.log('PASS: chart entrance threshold, partial exit, replay');

assert.match(source, /animation:bar-rise 350ms[^}]*both/);
for(let i=2;i<=7;i++) assert.ok(source.includes(`.bar-column:nth-child(${i}) .bar-fill{animation-delay:${(i-1)*350}ms}`));
console.log('PASS: sequential bars, 350 ms each with delayed start');

const finishBar = last => element('incomeChart').listeners.animationend({animationName:'bar-rise',target:{matches:()=>last}});
finishBar(false); assert.equal(element('chartCelebration').classes.has('playing'),false);
finishBar(true); assert.equal(element('chartCelebration').classes.has('playing'),true);
element('chartCelebration').listeners.animationend();
assert.equal(element('chartCelebration').classes.has('playing'),false);
finishBar(true); assert.equal(element('chartCelebration').classes.has('playing'),true,'Each completed chart must replay celebration');
enter(false,0); assert.equal(element('chartCelebration').classes.has('playing'),false,'Leaving chart cancels celebration');
enter(true,.5);
finishBar(true); assert.equal(element('chartCelebration').classes.has('playing'),true);
element('chartCelebration').listeners.animationend();
context.window.matchMedia=()=>({matches:true});
finishBar(true); assert.equal(element('chartCelebration').classes.has('playing'),false,'Reduced motion skips character');
console.log('PASS: celebration after last bar only, every chart completion, cancels on exit, hides on finish, reduced motion');
