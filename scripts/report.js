const rows = Array.from(document.querySelectorAll('#application-rows tr'));
let current = null;
function visibleRows(){return rows.filter(row => !row.hidden);}
function applyFilters(){
    const query = document.getElementById('search').value.toLowerCase();
    const filter = document.getElementById('filter').value;
    const status = document.getElementById('status-filter').value;
    rows.forEach(row => {row.hidden = !(row.dataset.search.includes(query) && (filter === 'all' || row.getAttribute('data-' + filter) === 'true') && (status === 'all' || row.dataset.status === status));});
    document.getElementById('shown').textContent = visibleRows().length + ' applications shown · click an application to view all details';
}
function openApp(id){
    const dialog = document.getElementById(id);
    if (!dialog) return;
    if (current) current.close();
    current = dialog;
    const visible = visibleRows();
    const index = visible.findIndex(row => row.dataset.target === id);
    dialog.querySelector('.dialog-position').textContent = index >= 0 ? (index + 1) + ' / ' + visible.length : 'Registration only';
    dialog.querySelector('[data-previous]').disabled = index <= 0;
    dialog.querySelector('[data-next]').disabled = index < 0 || index >= visible.length - 1;
    dialog.showModal();
    dialog.scrollTop = 0;
}
function navigate(offset){
    if (!current) return;
    const visible = visibleRows();
    const index = visible.findIndex(row => row.dataset.target === current.id);
    if (index >= 0 && visible[index + offset]) openApp(visible[index + offset].dataset.target);
}
rows.forEach(row => row.addEventListener('click',() => openApp(row.dataset.target)));
document.querySelectorAll('[data-open-app]').forEach(button => button.addEventListener('click',() => openApp(button.dataset.openApp)));
document.querySelectorAll('dialog.app').forEach(dialog => {
    dialog.querySelector('.close-dialog').addEventListener('click',() => dialog.close());
    dialog.querySelector('[data-previous]').addEventListener('click',() => navigate(-1));
    dialog.querySelector('[data-next]').addEventListener('click',() => navigate(1));
    dialog.addEventListener('close',() => {if (current === dialog) current = null;});
    dialog.addEventListener('click',event => {if (event.target === dialog){const box = dialog.getBoundingClientRect();if(event.clientX < box.left || event.clientX > box.right || event.clientY < box.top || event.clientY > box.bottom) dialog.close();}});
});
document.getElementById('search').addEventListener('input',applyFilters);
document.getElementById('filter').addEventListener('change',applyFilters);
document.getElementById('status-filter').addEventListener('change',applyFilters);
document.getElementById('sidebar-toggle').addEventListener('click',() => document.body.classList.toggle('sidebar-collapsed'));
document.getElementById('theme-toggle').addEventListener('click',() => {const dark = document.body.classList.toggle('dark');document.getElementById('theme-toggle').setAttribute('aria-label',dark ? 'Switch to light mode' : 'Switch to dark mode');});
document.getElementById('print-report').addEventListener('click',() => window.print());
document.addEventListener('keydown',event => {if(current && !['INPUT','SELECT','TEXTAREA'].includes(event.target.tagName)){if(event.key === 'ArrowLeft') navigate(-1);if(event.key === 'ArrowRight') navigate(1);}});
document.querySelectorAll('.sidebar nav a[href^="#"]').forEach(link => link.addEventListener('click',() => {document.querySelectorAll('.sidebar nav a').forEach(item => item.classList.remove('active'));link.classList.add('active');if(link.getAttribute('href') === '#coverage') document.getElementById('coverage').open = true;}));
applyFilters();
