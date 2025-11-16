classdef Patient
    %PATIENT  Simple class for storing patient details

    properties
        ID (1,1) double = 0
        Name (1,1) string
        Age (1,1) double
        Diagnosis (1,1) string
        Treatment (1,1) string
    end

    methods
        function obj = Patient(id, name, age, diagnosis, treatment)
            % Constructor to create a new patient objecSt
            if nargin > 0
                obj.ID        = id;
                obj.Name      = string(name);
                obj.Age       = age;
                obj.Diagnosis = string(diagnosis);
                obj.Treatment = string(treatment);
            end
        end

        function show(obj)
            % Display patient details neatly
            fprintf('ID: %d | Name: %s | Age: %d | Diagnosis: %s | Treatment: %s\n', ...
                obj.ID, char(obj.Name), obj.Age, char(obj.Diagnosis), char(obj.Treatment));
        end
    end
end