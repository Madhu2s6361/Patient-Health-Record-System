% main.m — Simple Patient Health Record System
clear; clc;

filename = 'patients.mat';     % File where data will be saved
patients = [];                 % Array of Patient objects

% ---- MENU LOOP ----
while true
    fprintf('\n=== PATIENT HEALTH RECORD SYSTEM ===\n');
    fprintf('1. Add Patient\n');
    fprintf('2. View All Patients\n');
    fprintf('3. Search by Name\n');
    fprintf('4. Save Records\n');
    fprintf('5. Load Records\n');
    fprintf('0. Exit\n');
    choice = input('Enter your choice: ');

    switch choice
        case 1
            id = numel(patients) + 1;
            name = input('Enter patient name: ', 's');
            age = input('Enter age: ');
            diagnosis = input('Enter diagnosis: ', 's');
            treatment = input('Enter treatment: ', 's');
            newPatient = Patient(id, name, age, diagnosis, treatment);
            patients = [patients; newPatient]; %#ok<AGROW>
            disp('Patient added successfully.');

        case 2
            if isempty(patients)
                disp('No patients found.');
            else
                disp('All Patient Records:');
                for i = 1:numel(patients)
                    patients(i).show();
                end
            end

        case 3
            if isempty(patients)
                disp('No records to search.');
            else
                nameQuery = lower(string(input('Enter name to search: ', 's')));
                found = false;
                for i = 1:numel(patients)
                    if contains(lower(patients(i).Name), nameQuery)
                        patients(i).show();
                        found = true;
                    end
                end
                if ~found
                    disp('No matching records found.');
                end
            end

        case 4
            save(filename, 'patients');
            disp(['Records saved to ' filename]);

        case 5
            if isfile(filename)
                load(filename, 'patients');
                disp('Records loaded successfully.');
            else
                disp('No saved file found.');
            end

        case 0
            disp('Exiting system. Goodbye!');
            break;

        otherwise
            disp('Invalid choice. Try again.');
    end
end
