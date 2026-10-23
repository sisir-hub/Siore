import {headers} from 'next/headers';
import html from '../../admin.html?raw';
import {getAccess} from '../../lib/access';
export const dynamic='force-dynamic';
export async function GET(){const h=await headers();if(!h.get('oai-authenticated-user-id'))return new Response(null,{status:302,headers:{Location:'/signin-with-chatgpt?return_to=/admin'}});if(!await getAccess(h))return new Response('Staff access required',{status:403});return new Response(html,{headers:{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store'}})}
