module customer_quota::example {
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use std::string::{Self, String};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::object_table::{Self, ObjectTable};

    //const DISCOUNT_PERCENTAGE: u8 = 50;

    //const EUnequalObjects: u64 = 0;
    const EKeyMismatch: u64 = 0;

    struct AdminRight has key {
        id: UID
    }

    struct EmployeeRight has key {
        id: UID
    }

    struct Employee has key, store {
        id: UID,
        owner: address,
        remainder: u8
    }

    struct Company has key {
        id: UID,
        name: String,
        balance: Balance<SUI>,
        product_counter: u8,
        employee_counter: u8,
        products: ObjectTable<u8, Product>,
        employees: ObjectTable<u8, Employee>
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            AdminRight {id: object::new(ctx)}, 
            tx_context::sender(ctx)
        );
        transfer::share_object(
            Company {
                id: object::new(ctx),
                balance: balance::zero(),
                name: string::utf8(b"Company A"),
                product_counter: 0,
                employee_counter: 0,
                products: object_table::new(ctx),
                employees: object_table::new(ctx)
            }
        );
    }

    public entry fun add_employee(
        _: &mut AdminRight,
        owner: address,
        company: &mut Company,
        ctx: &mut TxContext
    ) {
        let employee = Employee {
            id: object::new(ctx),
            owner: owner,
            remainder: 5
        };

        transfer::transfer(
            EmployeeRight { id: object::new(ctx) },
            owner
        );

        company.employee_counter = company.employee_counter + 1;
        object_table::add(&mut company.employees, company.employee_counter, employee);
    }

    struct Request has key {
        id: UID,
        exchange_key: String,
        owner: address,
        obj: Product,
        fee: u64
    }

    struct Product has key, store {
        id: UID,
        name: String,
        fee: u64
    }

    public entry fun create_product(
        _: &EmployeeRight,
        name: vector<u8>,
        fee: u64,
        company: &mut Company,
        ctx: &mut TxContext
    ) {
        let product = Product {
            id: object::new(ctx),
            name: string::utf8(name),
            fee: fee
        };

        company.product_counter = company.product_counter + 1;
        object_table::add(&mut company.products, company.product_counter, product);
    }

    public entry fun create_request(
        _: &EmployeeRight,
        product: Product,
        exchange_key: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);

        let request = Request {
            id: object::new(ctx),
            owner: sender,
            fee: product.fee,
            obj: product,
            exchange_key: string::utf8(exchange_key)
        };

        transfer::transfer(request, sender);
    }

    public entry fun buy_product(
        request: Request,
        company: &mut Company,
        payment: &mut Coin<SUI>,
        exchange_key: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender_id = tx_context::sender(ctx);
        assert!(
            request.exchange_key == string::utf8(exchange_key), 
            EKeyMismatch
        );
        /*assert!(
            request.id == sender_id, 
            EKeyMismatch
        );*/

        let Request {
            id: id,
            obj: obj,
            owner: _,
            fee: fee,
            exchange_key: _
        } = request;

        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, fee);

        balance::join(&mut company.balance, paid);
        object::delete(id);

        transfer::transfer(
            obj, 
            sender_id
        );
    }

    public entry fun collect_profits(
        _: &AdminRight, 
        company: &mut Company, 
        ctx: &mut TxContext
    ) {
        let amount = balance::value(&company.balance);
        let profits = coin::take(&mut company.balance, amount, ctx);
        
        transfer::public_transfer(profits, tx_context::sender(ctx));
    }

    #[test]
    public fun test_object_creation() {
        use sui::test_scenario;

        let admin = @0xBABE;
        let employee = @0xFABE;
        //let customer = @0xFACE;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            init(test_scenario::ctx(scenario));
        };


        let company: Company = test_scenario::take_shared(scenario);

        test_scenario::next_tx(scenario, admin);
        {
            let ctx = test_scenario::ctx(scenario);

            let admin_right = AdminRight { id: object::new(ctx) };
            add_employee(&mut admin_right, employee, &mut company, ctx);
            
            assert!(object_table::length(&company.employees) == 1, 1);
            
            transfer::transfer(admin_right, admin);
            
        };

        test_scenario::next_tx(scenario, employee);
        {
            let ctx = test_scenario::ctx(scenario);
            //let company: Company = test_scenario::take_shared(scenario);
            
            let txt = b"Hello!\n";
            
            let employee_right = EmployeeRight { id: object::new(ctx) };

            create_product(&employee_right, txt, 2, &mut company, ctx);
            assert!(object_table::length(&company.products) == 1, 1);

            transfer::transfer(employee_right, employee);
        };

        test_scenario::return_shared(company);
        test_scenario::end(scenario_val);
    }
}