-- Enforce Apple-only device selection for new tickets
-- Keep constraints NOT VALID to avoid breaking existing data; validate after cleanup.

ALTER TABLE public.tickets
    ADD CONSTRAINT tickets_device_type_apple
    CHECK (device_type IN ('iPhone', 'iPad', 'Mac', 'Watch')) NOT VALID;

ALTER TABLE public.tickets
    ADD CONSTRAINT tickets_device_model_required
    CHECK (device_model IS NOT NULL AND length(trim(device_model)) > 0) NOT VALID;
