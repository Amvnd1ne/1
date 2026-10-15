/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: amandahuaman
 * Дата: 28.05.26
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
select * from players_stat;
select players_count, payers_count, paid_share
from players_stat;
-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
select r.race,
sum (u.payer), count(*),round (100*sum(u.payer)/count(*),2)
from fantasy.users u
join fantasy.race r on u.race_id = r.race_id
group by r.race
order by round (100.0 *sum(u.payer)/count(*),1) desc;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
select count(*),sum(amount),min(amount),max(amount),
round(avg(amount)::numeric, 2), 
round(percentile_cont(0.5) within group (order by amount)::numeric, 2),round(stddev(amount)::numeric, 2)
from fantasy.events;

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
select count(*),round(100.0*count(*)/(select count(*) from fantasy.events),4)
from fantasy.events
where amount=0;
-- 2.3: Популярные эпические предметы:
-- Напишите ваш запрос здесь
    count(*) as p_c, round(100.0 * count(*) / (select count(*) from fantasy.events where amount > 0), 4) as p_p,
    count(distinct e.id),
    round(100.0 * count(distinct e.id) / (select count(distinct id) from fantasy.events where amount > 0), 4) as b_p
from fantasy.events e
join fantasy.items i on e.item_code = i.item_code 
where e.amount > 0 
  and i.item_code >= 8000 
group by i.item_code, i.game_items 
order by p_c desc;


-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
with epic_items as (select item_code from fantasy.items where item_code >= 8000),
epic_purchases as (select e.id as player_id, e.amount, u.race_id
from fantasy.events e join fantasy.users u on e.id = u.id   
where e.amount > 0  and e.item_code in (select item_code from epic_items)),
player_stats as (select r.race,
count(distinct u.id) as total_players,count(distinct ep.player_id) as buyers,count(ep.player_id) as total_purchases,coalesce(sum(ep.amount), 0) as total_amount
from fantasy.users u  join fantasy.race r on u.race_id = r.race_id  left join epic_purchases ep on u.id = ep.player_id and u.race_id = ep.race_id group by r.race)
select race as "раса", total_players as "всего", buyers as "купили э",
(100.0 * buyers / total_players)::numeric(10,2) as "доля в %",(100.0 * buyers / nullif(buyers, 0))::numeric(10,2) as "доля платящих в%",
(1.0 * total_purchases / nullif(buyers, 0))::numeric(10,2) as "среднее количество покупок на одного",(1.0 * total_amount / nullif(total_purchases, 0))::numeric(10,2) as "средняя цена",(1.0 * total_amount / nullif(buyers, 0))::numeric(10,2) as "средняя сумма на одного"
from player_stats where buyers > 0 order by buyers desc;