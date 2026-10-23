import {can} from './access';
export const STATUSES=['Pending','On Hold','Processing','Ready to Ship','In-Transit','Delivered','Returned','Cancelled','Return Requested','Confirmed','Packed','Dispatched'];
export const SOURCES=['Website','Messenger','Instagram','Facebook','POS'];
export function filters(url:URL,a:any,includeStatus=true){
 const p=url.searchParams,clauses:string[]=[],values:any[]=[];
 if(!can(a,'orders.read.all')){clauses.push('o.created_by=?');values.push(a.email)}
 const basis=p.get('basis')||'created';if(!['created','status'].includes(basis))throw Error('Invalid date basis');
 const stamp=basis==='status'?"COALESCE((SELECT MAX(h.at) FROM order_history h WHERE h.order_id=o.id AND h.status=o.status),o.created_at)":'o.created_at';
 const from=p.get('from')||'',to=p.get('to')||'';
 function boundary(d:string,end=false){if(!/^\d{4}-\d{2}-\d{2}$/.test(d)||new Date(d+'T00:00:00Z').toISOString().slice(0,10)!==d)throw Error('Invalid date');return new Date(new Date(d+'T00:00:00+06:00').getTime()+(end?86400000:0)).toISOString()}
 if(from){clauses.push(stamp+'>=?');values.push(boundary(from))}if(to){clauses.push(stamp+'<?');values.push(boundary(to,true))}if(from&&to&&from>to)throw Error('Start date must precede end date');
 const status=p.get('status');if(status&&!STATUSES.includes(status))throw Error('Invalid order status');if(status&&includeStatus){clauses.push('o.status=?');values.push(status)}
 const source=p.get('source');if(source){if(!SOURCES.includes(source))throw Error('Invalid source');clauses.push('o.source=?');values.push(source)}
 const courier=p.get('courier');if(courier){if(courier==='unassigned')clauses.push('o.courier_id IS NULL');else {if(!/^[a-f0-9-]{36}$/.test(courier))throw Error('Invalid courier');clauses.push('o.courier_id=?');values.push(courier)}}
 const q=p.get('q')?.trim();if(q){if(q.length>100)throw Error('Search too long');clauses.push(`(o.id LIKE ? OR o.name LIKE ? OR o.phone LIKE ? OR o.consignment LIKE ? OR EXISTS(SELECT 1 FROM order_numbers sn WHERE sn.order_id=o.id AND ('SIO-'||printf('%06d',sn.number)) LIKE ?))`);values.push(...Array(5).fill('%'+q+'%'))}
 return {where:clauses.length?' WHERE '+clauses.join(' AND '):'',values,stamp,basis,from,to};
}
export async function report(database:any,url:URL,a:any){const f=filters(url,a);const rows=(await database.prepare(`SELECT o.status,COUNT(*) count,COALESCE(SUM(o.subtotal-o.discount),0) merchandise,COALESCE(SUM(o.shipping),0) delivery,COALESCE(SUM(o.total),0) total FROM orders o${f.where} GROUP BY o.status`).bind(...f.values).all()).results;
 const status=STATUSES.map(s=>({status:s,...(rows.find((r:any)=>r.status===s)||{count:0,merchandise:0,delivery:0,total:0})}));
 const daily=(await database.prepare(`SELECT date(${f.stamp},'+6 hours') date,COUNT(*) orders,COALESCE(SUM(o.total),0) order_value,SUM(CASE WHEN o.status='Delivered' THEN 1 ELSE 0 END) delivered,SUM(CASE WHEN o.status='Delivered' THEN o.subtotal-o.discount ELSE 0 END) delivered_sales,SUM(CASE WHEN o.status='Returned' THEN 1 ELSE 0 END) returned,SUM(CASE WHEN o.status='Returned' THEN o.subtotal-o.discount ELSE 0 END) return_value,SUM(CASE WHEN o.status='Cancelled' THEN 1 ELSE 0 END) cancelled FROM orders o${f.where} GROUP BY 1 ORDER BY 1 DESC`).bind(...f.values).all()).results;
 return {timezone:'Asia/Dhaka',basis:f.basis,from:f.from,to:f.to,status,daily,summary:{orders:status.reduce((n:number,r:any)=>n+r.count,0),orderValue:status.reduce((n:number,r:any)=>n+r.total,0),delivered:status.find(r=>r.status==='Delivered'),returned:status.find(r=>r.status==='Returned'),cancelled:status.find(r=>r.status==='Cancelled')},note:'Current order status; sales include manual discounts and exclude delivery charges. Values are not profit or verified payments. Status date means the latest event matching the current status.'};}
