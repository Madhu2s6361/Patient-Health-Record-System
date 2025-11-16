function Patient_GUI()
% Patient_GUI  Simple GUI for the Patient Health Record System
% Save this as Patient_GUI.m and make sure Patient.m is in the same folder.

    % Data storage (in outer scope so callbacks can access) 
    filename = 'patients.mat';
    patients = Patient.empty(0,1); % object array
    selectedRow = [];              % currently selected table row index

    % Create UI 
    fig = uifigure('Name','Patient Health Record System','Position',[300 200 800 480]);

    % Left: form inputs
    lbl = uilabel(fig,'Text','Name:','Position',[20 410 60 22]);
    nameField = uieditfield(fig,'text','Position',[90 410 220 22]);

    lbl = uilabel(fig,'Text','Age:','Position',[20 370 60 22]);
    ageField = uieditfield(fig,'numeric','Position',[90 370 100 22],'Limits',[0 150]);

    lbl = uilabel(fig,'Text','Diagnosis:','Position',[20 330 60 22]);
    diagnosisField = uieditfield(fig,'text','Position',[90 330 220 22]);

    lbl = uilabel(fig,'Text','Treatment:','Position',[20 290 60 22]);
    treatmentField = uieditfield(fig,'text','Position',[90 290 220 22]);

    % Buttons: Add, Update, Delete, Clear
    addBtn = uibutton(fig,'push','Text','Add Patient','Position',[20 240 120 30],...
        'ButtonPushedFcn',@(btn,event) onAdd());
    updateBtn = uibutton(fig,'push','Text','Update Selected','Position',[150 240 120 30],...
        'ButtonPushedFcn',@(btn,event) onUpdate());
    delBtn = uibutton(fig,'push','Text','Delete Selected','Position',[20 200 120 30],...
        'ButtonPushedFcn',@(btn,event) onDelete());
    clearBtn = uibutton(fig,'push','Text','Clear Fields','Position',[150 200 120 30],...
        'ButtonPushedFcn',@(btn,event) clearFields());

    % Search box
    lbl = uilabel(fig,'Text','Search (Name):','Position',[20 160 100 20]);
    searchField = uieditfield(fig,'text','Position',[120 160 150 22]);
    searchBtn = uibutton(fig,'push','Text','Search','Position',[280 160 60 22],...
        'ButtonPushedFcn',@(btn,event) onSearch());
    showAllBtn = uibutton(fig,'push','Text','Show All','Position',[350 160 80 22],...
        'ButtonPushedFcn',@(btn,event) updateTable());

    % Save / Load
    saveBtn = uibutton(fig,'push','Text','Save Records','Position',[20 120 120 30],...
        'ButtonPushedFcn',@(btn,event) onSave());
    loadBtn = uibutton(fig,'push','Text','Load Records','Position',[150 120 120 30],...
        'ButtonPushedFcn',@(btn,event) onLoad());

    % Status label
    statusLabel = uilabel(fig,'Text','Ready.','Position',[20 90 420 18],'HorizontalAlignment','left');

    % Right: Table for records
    tbl = uitable(fig, ...
        'Position',[420 60 360 380], ...
        'ColumnName',{'ID','Name','Age','Diagnosis','Treatment'}, ...
        'ColumnEditable',[false true true true true], ...
        'CellSelectionCallback',@(src,event) onCellSelect(event), ...
        'CellEditCallback',@(src,event) onCellEdit(event) ...
        );

    % Initialize empty table
    updateTable();

    % Callback functions 
    function onAdd()
        % Validate inputs
        n = strtrim(nameField.Value);
        a = ageField.Value;
        d = strtrim(diagnosisField.Value);
        t = strtrim(treatmentField.Value);

        if isempty(n)
            uialert(fig,'Name is required.','Input error');
            return
        end
        if isempty(a) || ~isnumeric(a) || isnan(a)
            uialert(fig,'Enter a valid age.','Input error');
            return
        end

        id = numel(patients) + 1;
        newP = Patient(id, n, a, d, t);
        patients(end+1,1) = newP; %#ok<AGROW>
        updateTable();
        clearFields();
        statusLabel.Text = sprintf('Added patient ID %d.', id);
    end

    function onUpdate()
        % Update the selected patient from fields
        if isempty(selectedRow)
            uialert(fig,'Select a row first to update.','Selection required');
            return
        end
        idx = selectedRow;
        if idx < 1 || idx > numel(patients)
            uialert(fig,'Invalid selection.','Error');
            return
        end
        % Get values from fields (fall back to existing if empty)
        n = nameField.Value;
        a = ageField.Value;
        d = diagnosisField.Value;
        t = treatmentField.Value;

        if isempty(strtrim(n))
            uialert(fig,'Name is required.','Input error');
            return
        end

        patients(idx).Name = string(n);
        patients(idx).Age = a;
        patients(idx).Diagnosis = string(d);
        patients(idx).Treatment = string(t);

        updateTable();
        statusLabel.Text = sprintf('Updated patient ID %d.', patients(idx).ID);
    end

    function onDelete()
        if isempty(selectedRow)
            uialert(fig,'Select a row first to delete.','Selection required');
            return
        end
        idx = selectedRow;
        if idx < 1 || idx > numel(patients)
            uialert(fig,'Invalid selection.','Error');
            return
        end
        % Confirm
        sel = uiconfirm(fig,sprintf('Delete patient ID %d?', patients(idx).ID),'Confirm Delete',...
            'Options',{'Yes','No'},'DefaultOption',2);
        if strcmp(sel,'Yes')
            patients(idx) = [];
            % reassign IDs to remain sequential
            for k = 1:numel(patients)
                patients(k).ID = k;
            end
            selectedRow = [];
            updateTable();
            statusLabel.Text = 'Record deleted.';
        else
            statusLabel.Text = 'Delete cancelled.';
        end
    end

    function onSave()
        try
            save(filename,'patients');
            statusLabel.Text = ['Records saved to ' filename];
        catch ME
            uialert(fig,ME.message,'Save Error');
        end
    end

    function onLoad()
        if isfile(filename)
            S = load(filename,'patients');
            patients = S.patients;
            % ensure it's a column object array
            patients = reshape(patients,[],1);
            updateTable();
            statusLabel.Text = 'Records loaded.';
        else
            uialert(fig,'No saved file found.','Load Error');
        end
    end

    function onSearch()
        q = lower(string(searchField.Value));
        if strlength(strtrim(q)) == 0
            updateTable();
            return
        end
        % build filtered cell data
        data = patientsToCell(patients);
        if isempty(data)
            tbl.Data = {};
            statusLabel.Text = 'No records.';
            return
        end
        mask = false(size(data,1),1);
        for r = 1:size(data,1)
            nm = lower(string(data{r,2}));
            if contains(nm,q)
                mask(r) = true;
            end
        end
        tbl.Data = data(mask,:);
        statusLabel.Text = sprintf('Showing %d match(es).', sum(mask));
    end

    function onCellSelect(event)
        % event.Indices is N-by-2 array of selected cells
        if isempty(event.Indices)
            selectedRow = [];
            return
        end
        selectedRow = event.Indices(1,1); % take the first selected row
        % populate fields from selected patient
        if selectedRow <= numel(patients)
            p = patients(selectedRow);
            nameField.Value = char(p.Name);
            ageField.Value = double(p.Age);
            diagnosisField.Value = char(p.Diagnosis);
            treatmentField.Value = char(p.Treatment);
            statusLabel.Text = sprintf('Selected row %d (ID %d).', selectedRow, p.ID);
        end
    end

    function onCellEdit(event)
        % When user edits the table directly, update the object as well.
        % event.Indices = [row col], event.NewData
        if isempty(event.Indices)
            return
        end
        row = event.Indices(1);
        col = event.Indices(2);
        val = event.NewData;
        if row <= numel(patients)
            switch col
                case 2 % Name
                    patients(row).Name = string(val);
                case 3 % Age
                    patients(row).Age = double(val);
                case 4 % Diagnosis
                    patients(row).Diagnosis = string(val);
                case 5 % Treatment
                    patients(row).Treatment = string(val);
            end
            statusLabel.Text = sprintf('Edited row %d.', row);
        end
    end

    function updateTable()
        % Build cell array for table from patients
        tbl.Data = patientsToCell(patients);
    end

    function data = patientsToCell(plist)
        n = numel(plist);
        if n == 0
            data = {};
            return
        end
        data = cell(n,5);
        for k = 1:n
            data{k,1} = plist(k).ID;
            data{k,2} = char(plist(k).Name);
            data{k,3} = plist(k).Age;
            data{k,4} = char(plist(k).Diagnosis);
            data{k,5} = char(plist(k).Treatment);
        end
    end

    function clearFields()
        nameField.Value = '';
        ageField.Value = [];
        diagnosisField.Value = '';
        treatmentField.Value = '';
        selectedRow = [];
        statusLabel.Text = 'Fields cleared.';
    end

end
