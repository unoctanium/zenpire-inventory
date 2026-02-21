-- 1) permission
insert into public.permission (code, description)
values ('unit.manage', 'Manage units')
on conflict (code) do nothing;

-- 2) attach to admin role
insert into public.role_permission (role_id, permission_id)
select r.id, p.id
from public.role r
join public.permission p on p.code = 'unit.manage'
where r.code = 'admin'
on conflict do nothing;