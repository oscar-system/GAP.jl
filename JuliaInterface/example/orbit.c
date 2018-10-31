Obj bahn_c(Obj self, Obj elem, Obj gens, Obj action)
{
    Obj work_set = NEW_PLIST(T_PLIST, 1);
    SET_LEN_PLIST(work_set, 1);
    SET_ELM_PLIST(work_set, 1, elem);
    Obj return_set = NEW_PLIST(T_PLIST, 1);
    SET_LEN_PLIST(return_set, 1);
    SET_ELM_PLIST(return_set, 1, elem);
    int generator_length = LEN_PLIST(gens);
    while (LEN_PLIST(work_set) > 0) {
        Obj current_element = PopPlist(work_set);
        for (int i = 1; i <= generator_length; i++) {
            Obj current_generator = ELM_PLIST(gens, i);
            Obj current_result =
                CALL_2ARGS(action, current_element, current_generator);
            int is_in_set = 0;
            for (int i = 1; i <= LEN_PLIST(return_set); i++) {
                if (current_result == ELM_PLIST(return_set, i)) {
                    is_in_set = 1;
                    break;
                }
            }
            if (is_in_set == 0) {
                PushPlist(return_set, current_result);
                CHANGED_BAG(return_set);
                PushPlist(work_set, current_result);
                CHANGED_BAG(work_set);
            }
        }
    }
    return return_set;
}
