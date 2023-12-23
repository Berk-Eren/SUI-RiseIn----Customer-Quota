#[test_only]
module customer_quota::test {
    use sui::transfer;
    use sui::object_table;
    use sui::test_scenario;
    use customer_quota::contract::{Self, Company, AdminRight, EmployeeRight};
    
    #[test]
    public fun test_object_creation() {
        let admin = @0xBABE;
        let employee = @0xFABE;
        //let customer = @0xFACE;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        let ctx;
        
        let admin_right: AdminRight;
        
        test_scenario::next_tx(scenario, admin);
        {
            contract::init_for_testing(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, admin);
        {    
            let company: Company = test_scenario::take_shared(scenario);
            let admin_right: AdminRight = test_scenario::take_from_sender<AdminRight>(scenario);
            contract::add_employee(&mut admin_right, employee, &mut company, ctx);

            assert!(contract::get_number_of_employees(company) == 1, 1);

            test_scenario::return_shared(company);
        };
        

        {
            
            let ctx = test_scenario::ctx(scenario);
            let company: Company = test_scenario::take_shared(scenario);
            let employee_right: EmployeeRight = test_scenario::take_from_sender<EmployeeRight>(scenario);
            
            let txt = b"Hello!\n";

            contract::create_product(&mut employee_right, txt, 2, &mut company, ctx);
            assert!(object_table::length(&company.products) == 1, 1);

            transfer::transfer(employee_right, employee);
            test_scenario::return_shared(company);
        };

        test_scenario::end(scenario_val);
    }
}
