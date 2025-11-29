# Supabase Setup Instructions

To connect AgriFlow to your Supabase backend, follow these steps:

## 1. Create a Supabase Project
1. Go to [supabase.com](https://supabase.com) and create a new project.
2. Wait for the database to start.

## 2. Get Credentials
1. Go to **Project Settings > API**.
2. Copy the **Project URL**.
3. Copy the **anon public key**.
4. Open `lib/config/supabase_config.dart` in this project.
5. Paste the values into the `url` and `anonKey` fields.

## 3. Setup Database Schema
1. Go to the **SQL Editor** in your Supabase dashboard.
2. Create a new query and paste the following SQL:

```sql
-- Create Cattle Groups Table
create table cattle_groups (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  breed text not null,
  quantity int not null,
  weight_bucket text not null,
  county text not null,
  desired_price_per_kg float not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Create Price Pulses Table (for market data)
create table price_pulses (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users,
  cattle_type text not null,
  location_region text not null,
  weight_kg float not null,
  desired_price_per_kg float not null,
  offered_price_per_kg float not null,
  submission_date timestamptz default now()
);

-- Enable Row Level Security (RLS)
alter table cattle_groups enable row level security;
alter table price_pulses enable row level security;

-- Cattle Groups Policies
create policy "Users can see their own groups"
on cattle_groups for select
using (auth.uid() = user_id);

create policy "Users can insert their own groups"
on cattle_groups for insert
with check (auth.uid() = user_id);

create policy "Users can delete their own groups"
on cattle_groups for delete
using (auth.uid() = user_id);

-- Price Pulses Policies (public read, authenticated write)
create policy "Anyone can view price pulses"
on price_pulses for select
using (true);

create policy "Authenticated users can submit price pulses"
on price_pulses for insert
with check (auth.uid() is not null);
```

3. Click **Run**.

## 4. Enable Authentication
1. Go to **Authentication > Providers**.
2. Expand **Anonymous Sign-ins**.
3. Toggle **Enable Anonymous Sign-ins** to ON.
4. Click **Save**.

## 5. Restart App
1. Stop the running app.
2. Run `flutter run -d windows` again.
