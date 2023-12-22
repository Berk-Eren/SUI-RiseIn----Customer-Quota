module customer_quota::example {
    use sui::transfer;
    use std::string::{Self, String};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::object_table::{Self, ObjectTable};

    const EUnequalObjects: u64 = 0;
    const EKeyMismatch: u64 = 1;

    struct AdminRight has key {
        id: UID
    }

    struct EmployeeRight has key {
        id: UID
    }

    struct Product has key, store {
        id: UID,
        name: String,
        fee: u8
    }

    struct Employee has key, store {
        id: UID,
        owner: address,
        remainder: u8
    }

    struct Request has key {
        id: UID,
        exchange_key: String,
        obj: Product,
        fee: u8
    }

    struct Company has key {
        id: UID,
        name: String,
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

    public entry fun create_product(
        _: &EmployeeRight,
        name: vector<u8>,
        fee: u8,
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
        let request = Request {
            id: object::new(ctx),
            fee: product.fee,
            obj: product,
            exchange_key: string::utf8(exchange_key)
        };

        transfer::transfer(request, tx_context::sender(ctx));
    }

    public entry fun buy_product(
        request: Request,
        fee: u8,
        exchange_key: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(request.exchange_key == string::utf8(exchange_key), EKeyMismatch);
        assert!(request.fee == fee, EUnequalObjects);

        let Request {
            id: id,
            obj: obj,
            fee: _,
            exchange_key: _
        } = request;

        object::delete(id);
        transfer::transfer(obj, tx_context::sender(ctx));
    }

    #[test]
    public fun test_product_swapping() {
        use sui::test_scenario;

        let admin = @0xBABE;
        let employee = @0xFABE;
        //let customer = @0xFACE;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            init(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, admin);
        {
            let company: Company = test_scenario::take_shared(scenario);
            let ctx = test_scenario::ctx(scenario);

            let admin_right = AdminRight { id: object::new(ctx) };
            add_employee(&mut admin_right, employee, &mut company, ctx);
            transfer::transfer(admin_right, admin);
            test_scenario::return_shared(company);
        };

        test_scenario::next_tx(scenario, admin);
        {
            let company: Company = test_scenario::take_shared(scenario);
            let ctx = test_scenario::ctx(scenario);
            let txt = b"Hello!\n";
            let employee_right = EmployeeRight { id: object::new(ctx) };
            create_product(&employee_right, txt, 2, &mut company, ctx);
            transfer::transfer(employee_right, employee);
            test_scenario::return_shared(company);
        };

        test_scenario::end(scenario_val);
    }
}