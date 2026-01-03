import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "npm:@supabase/supabase-js@2";

declare const Deno: {
  env: {
    get: (name: string) => string | undefined;
  };
  serve: (handler: (req: Request) => Response | Promise<Response>) => void;
};

type Json = string | number | boolean | null | { [key: string]: Json } | Json[];

function jsonResponse(body: Json, init: ResponseInit = {}): Response {
  const headers = new Headers(init.headers);
  headers.set("Content-Type", "application/json");
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Headers", "authorization, content-type");
  headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");

  return new Response(JSON.stringify(body), {
    ...init,
    headers,
  });
}

function getEnvOrThrow(name: string): string {
  const v = Deno.env.get(name);
  if (!v) throw new Error(`Missing required environment variable: ${name}`);
  return v;
}

function squareBaseUrl(): string {
  const env = (Deno.env.get("SQUARE_ENV") ?? "production").toLowerCase();
  if (env === "sandbox") return "https://connect.squareupsandbox.com";
  return "https://connect.squareup.com";
}

function squareVersion(): string {
  return Deno.env.get("SQUARE_VERSION") ?? "2025-10-16";
}

async function squareFetch(path: string, init: RequestInit): Promise<Response> {
  const accessToken = getEnvOrThrow("SQUARE_ACCESS_TOKEN");
  const url = `${squareBaseUrl()}${path}`;

  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${accessToken}`);
  headers.set("Content-Type", "application/json");
  headers.set("Square-Version", squareVersion());

  return await fetch(url, { ...init, headers });
}

async function squareJson(path: string, init: RequestInit): Promise<any> {
  const res = await squareFetch(path, init);
  const text = await res.text();
  const json = text ? JSON.parse(text) : {};

  if (!res.ok) {
    const msg = json?.errors?.[0]?.detail ?? json?.errors?.[0]?.code ?? `Square API error (${res.status})`;
    throw new Error(msg);
  }

  return json;
}

function toCents(amount: number): number {
  return Math.round(amount * 100);
}

type CreateTerminalCheckoutBody = {
  action: "create_terminal_checkout";
  device_id: string;
  amount_cents?: number;
  reference_id?: string;
  note?: string;
  currency?: string;
  square_customer_id?: string;
  items?: Array<{
    name: string;
    quantity: number;
    unit_price_cents: number;
  }>;
};

type CreateCashPaymentBody = {
  action: "create_cash_payment";
  amount_cents: number;
  reference_id?: string;
  note?: string;
  currency?: string;
  square_customer_id?: string;
};

type GetTerminalCheckoutBody = {
  action: "get_terminal_checkout";
  checkout_id: string;
};

type CancelTerminalCheckoutBody = {
  action: "cancel_terminal_checkout";
  checkout_id: string;
};

type RequestBody =
  | CreateTerminalCheckoutBody
  | CreateCashPaymentBody
  | GetTerminalCheckoutBody
  | CancelTerminalCheckoutBody;

async function getShopIdForUser(supabase: ReturnType<typeof createClient>, userId: string): Promise<string> {
  const { data, error } = await supabase
    .from("employees")
    .select("shop_id")
    .eq("auth_user_id", userId)
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  if (!data?.shop_id) throw new Error("No employee record found for current user");
  return data.shop_id as string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return jsonResponse({ ok: true });
  }

  try {
    const supabaseUrl = getEnvOrThrow("SUPABASE_URL");
    const supabaseAnonKey = getEnvOrThrow("SUPABASE_ANON_KEY");

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing Authorization header" }, { status: 401 });
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError) {
      return jsonResponse({ error: userError.message }, { status: 401 });
    }

    const user = userData.user;
    if (!user) {
      return jsonResponse({ error: "Unauthorized" }, { status: 401 });
    }

    const body = (await req.json()) as RequestBody;

    switch (body.action) {
      case "create_terminal_checkout": {
        const currency = body.currency ?? "USD";
        const squareLocationId = getEnvOrThrow("SQUARE_LOCATION_ID");

        const shopId = await getShopIdForUser(supabase, user.id);

        const orderIdempotencyKey = crypto.randomUUID();

        let orderLineItems: any[];
        if (typeof body.amount_cents === "number") {
          orderLineItems = [
            {
              name: "ProTech Sale",
              quantity: "1",
              base_price_money: { amount: body.amount_cents, currency },
            },
          ];
        } else if (Array.isArray(body.items) && body.items.length > 0) {
          orderLineItems = body.items.map((i) => ({
            name: i.name,
            quantity: String(i.quantity),
            base_price_money: {
              amount: i.unit_price_cents,
              currency,
            },
          }));
        } else {
          return jsonResponse({ error: "Either amount_cents or items is required" }, { status: 400 });
        }

        const createOrderPayload: any = {
          idempotency_key: orderIdempotencyKey,
          order: {
            location_id: squareLocationId,
            reference_id: body.reference_id,
            note: body.note,
            customer_id: body.square_customer_id,
            line_items: orderLineItems,
          },
        };

        if (!body.reference_id) delete createOrderPayload.order.reference_id;
        if (!body.note) delete createOrderPayload.order.note;
        if (!body.square_customer_id) delete createOrderPayload.order.customer_id;

        const orderJson = await squareJson("/v2/orders", {
          method: "POST",
          body: JSON.stringify(createOrderPayload),
        });

        const order = orderJson.order;
        if (!order?.id) {
          throw new Error("Square order creation returned no order id");
        }

        const totalMoneyAmount: number | null = order?.total_money?.amount ?? null;
        const totalMoneyCurrency: string | null = order?.total_money?.currency ?? currency;

        const { error: insertOrderError } = await supabase
          .from("square_orders")
          .insert({
            shop_id: shopId,
            square_order_id: order.id,
            square_location_id: squareLocationId,
            square_customer_id: body.square_customer_id ?? null,
            reference_id: body.reference_id ?? null,
            note: body.note ?? null,
            state: order.state ?? null,
            total_money_amount: totalMoneyAmount,
            total_money_currency: totalMoneyCurrency,
            raw_order: order,
          });

        if (insertOrderError) throw insertOrderError;

        const checkoutIdempotencyKey = crypto.randomUUID();

        const fallbackTotalCents = Array.isArray(body.items)
          ? body.items.reduce((sum, i) => sum + i.unit_price_cents * i.quantity, 0)
          : body.amount_cents ?? 0;
        const amountMoney = {
          amount: totalMoneyAmount ?? fallbackTotalCents,
          currency: totalMoneyCurrency ?? currency,
        };

        const createCheckoutPayload: any = {
          idempotency_key: checkoutIdempotencyKey,
          checkout: {
            amount_money: amountMoney,
            device_options: {
              device_id: body.device_id,
            },
            reference_id: body.reference_id,
            note: body.note,
            order_id: order.id,
          },
        };

        if (!body.reference_id) delete createCheckoutPayload.checkout.reference_id;
        if (!body.note) delete createCheckoutPayload.checkout.note;

        const checkoutJson = await squareJson("/v2/terminals/checkouts", {
          method: "POST",
          body: JSON.stringify(createCheckoutPayload),
        });

        const checkout = checkoutJson.checkout;
        if (!checkout?.id) {
          throw new Error("Square terminal checkout creation returned no checkout id");
        }

        const { error: insertCheckoutError } = await supabase
          .from("square_terminal_checkouts")
          .insert({
            shop_id: shopId,
            square_checkout_id: checkout.id,
            square_order_id: order.id,
            device_id: body.device_id,
            reference_id: body.reference_id ?? null,
            note: body.note ?? null,
            status: checkout.status ?? null,
            payment_ids: checkout.payment_ids ?? null,
            raw_checkout: checkout,
          });

        if (insertCheckoutError) throw insertCheckoutError;

        return jsonResponse({
          ok: true,
          order_id: order.id,
          checkout_id: checkout.id,
          checkout_status: checkout.status,
          payment_ids: checkout.payment_ids ?? [],
        });
      }

      case "create_cash_payment": {
        const currency = body.currency ?? "USD";
        const squareLocationId = getEnvOrThrow("SQUARE_LOCATION_ID");

        const shopId = await getShopIdForUser(supabase, user.id);

        const orderIdempotencyKey = crypto.randomUUID();
        const createOrderPayload: any = {
          idempotency_key: orderIdempotencyKey,
          order: {
            location_id: squareLocationId,
            reference_id: body.reference_id,
            note: body.note,
            customer_id: body.square_customer_id,
            line_items: [
              {
                name: "ProTech Sale",
                quantity: "1",
                base_price_money: { amount: body.amount_cents, currency },
              },
            ],
          },
        };

        if (!body.reference_id) delete createOrderPayload.order.reference_id;
        if (!body.note) delete createOrderPayload.order.note;
        if (!body.square_customer_id) delete createOrderPayload.order.customer_id;

        const orderJson = await squareJson("/v2/orders", {
          method: "POST",
          body: JSON.stringify(createOrderPayload),
        });

        const order = orderJson.order;
        if (!order?.id) {
          throw new Error("Square order creation returned no order id");
        }

        const totalMoneyAmount: number | null = order?.total_money?.amount ?? body.amount_cents;
        const totalMoneyCurrency: string | null = order?.total_money?.currency ?? currency;

        const { error: insertOrderError } = await supabase
          .from("square_orders")
          .insert({
            shop_id: shopId,
            square_order_id: order.id,
            square_location_id: squareLocationId,
            square_customer_id: body.square_customer_id ?? null,
            reference_id: body.reference_id ?? null,
            note: body.note ?? null,
            state: order.state ?? null,
            total_money_amount: totalMoneyAmount,
            total_money_currency: totalMoneyCurrency,
            raw_order: order,
          });

        if (insertOrderError) throw insertOrderError;

        const paymentIdempotencyKey = crypto.randomUUID();
        const createPaymentPayload: any = {
          idempotency_key: paymentIdempotencyKey,
          source_id: "CASH",
          amount_money: {
            amount: totalMoneyAmount,
            currency: totalMoneyCurrency,
          },
          order_id: order.id,
          location_id: squareLocationId,
          autocomplete: true,
          reference_id: body.reference_id,
          note: body.note,
          customer_id: body.square_customer_id,
        };

        if (!body.reference_id) delete createPaymentPayload.reference_id;
        if (!body.note) delete createPaymentPayload.note;
        if (!body.square_customer_id) delete createPaymentPayload.customer_id;

        const paymentJson = await squareJson("/v2/payments", {
          method: "POST",
          body: JSON.stringify(createPaymentPayload),
        });

        const paymentId = paymentJson?.payment?.id;
        if (!paymentId) {
          throw new Error("Square cash payment creation returned no payment id");
        }

        return jsonResponse({
          ok: true,
          order_id: order.id,
          payment_id: paymentId,
        });
      }

      case "get_terminal_checkout": {
        const checkoutJson = await squareJson(`/v2/terminals/checkouts/${body.checkout_id}`, {
          method: "GET",
        });

        const checkout = checkoutJson.checkout;
        if (!checkout?.id) {
          throw new Error("Square terminal checkout get returned no checkout id");
        }

        const { error: updateError } = await supabase
          .from("square_terminal_checkouts")
          .update({
            status: checkout.status ?? null,
            payment_ids: checkout.payment_ids ?? null,
            raw_checkout: checkout,
          })
          .eq("square_checkout_id", checkout.id);

        if (updateError) throw updateError;

        return jsonResponse({
          ok: true,
          checkout_id: checkout.id,
          checkout_status: checkout.status,
          payment_ids: checkout.payment_ids ?? [],
        });
      }

      case "cancel_terminal_checkout": {
        const checkoutJson = await squareJson(`/v2/terminals/checkouts/${body.checkout_id}/cancel`, {
          method: "POST",
          body: JSON.stringify({}),
        });

        const checkout = checkoutJson.checkout;
        if (!checkout?.id) {
          throw new Error("Square terminal checkout cancel returned no checkout id");
        }

        const { error: updateError } = await supabase
          .from("square_terminal_checkouts")
          .update({
            status: checkout.status ?? null,
            payment_ids: checkout.payment_ids ?? null,
            raw_checkout: checkout,
          })
          .eq("square_checkout_id", checkout.id);

        if (updateError) throw updateError;

        return jsonResponse({
          ok: true,
          checkout_id: checkout.id,
          checkout_status: checkout.status,
          payment_ids: checkout.payment_ids ?? [],
        });
      }

      default:
        return jsonResponse({ error: "Unknown action" }, { status: 400 });
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return jsonResponse({ error: message }, { status: 500 });
  }
});
