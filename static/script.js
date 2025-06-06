const days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
const times = Array.from({length:14}, (_,i)=>i+8); // 8am-21pm

function formatTime(hour){
    const ampm = hour < 12 ? 'am' : 'pm';
    const h = hour % 12 === 0 ? 12 : hour % 12;
    return h + ampm;
}

function createCalendar(){
    const cal = document.getElementById('calendar');
    const table = document.createElement('table');
    const header = document.createElement('tr');
    header.appendChild(document.createElement('th'));
    days.forEach(d=>{
        const th=document.createElement('th');
        th.textContent=d;
        header.appendChild(th);
    });
    table.appendChild(header);

    times.forEach(t=>{
        const row=document.createElement('tr');
        const timeCell=document.createElement('td');
        timeCell.textContent=formatTime(t);
        row.appendChild(timeCell);
        days.forEach(d=>{
            const cell=document.createElement('td');
            cell.dataset.day=d;
            cell.dataset.time=t;
            cell.addEventListener('click',()=>cell.classList.toggle('selected'));
            row.appendChild(cell);
        });
        table.appendChild(row);
    });

    cal.appendChild(table);
}

function getAvailability(){
    const selected=document.querySelectorAll('#calendar td.selected');
    return Array.from(selected).map(c=>({day:c.dataset.day, time:c.dataset.time}));
}

document.addEventListener('DOMContentLoaded',()=>{
    createCalendar();
    document.getElementById('application-form').addEventListener('submit',async e=>{
        e.preventDefault();
        const form=e.target;
        const data={
            name:form.name.value,
            email:form.email.value,
            referral:form.referral.value,
            availability:getAvailability(),
            activities:Array.from(form.querySelectorAll('input[name="activities"]:checked')).map(i=>i.value)
        };
        const status=document.getElementById('status');
        status.textContent='Submitting...';
        try{
            const res=await fetch('/submit',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});
            if(!res.ok) throw new Error('Request failed');
            status.textContent='Thank you! Your application has been recorded.';
            form.reset();
            document.querySelectorAll('#calendar td.selected').forEach(c=>c.classList.remove('selected'));
        }catch(err){
            status.textContent='Error submitting form.';
        }
    });
});
