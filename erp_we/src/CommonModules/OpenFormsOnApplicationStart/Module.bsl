
#Region Public

// Returns an array whose elements are the structures of form parameters that you want to open when 
// the system starts working.
//
// Returns:
//	Array - an array whose elements are the structures of the form parameters that are required 
//		open at the start of the system:
//		* NameOfFormToRun - String - full name of the form to open.
//		* Role - String - name of the role that gives the user the right to run the form.
//		* RequiredSettings - Boolean - settings must be set for the form to open.
//		* SettingsFormName - String - if Settings = TRUE is required, this parameter specifies the full name
//			of the settings editing form.
//		* LaunchParameter - String - a startup parameter that will be checked for when the system starts,
//			the form will be opened if the startup parameter is passed or the form is configured to be opened by default 
//			(i.e. without checking the startup parameter).
//		* SettingsAreSet - Boolean - True - the settings required to open the form are set.
//		* Parameters - Structure - form parameters used when opening the form.
//		* OpenByDefault - Boolean - True-the form opens by default when the system starts working.
//
Function FormsOpenedOnApplicationStart() Export
	
	SetPrivilegedMode(True);

	ArrayOfFormsToOpen = New Array;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FormsOpenedOnApplicationStart.Ref AS OpenedForm,
	|	CASE
	|		WHEN ConfigureFormOpeningOnStartingApplication.User IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS SettingsAreSet,
	|	ConfigureFormOpeningOnStartingApplication.Parameters,
	|	CASE
	|		WHEN ConfigureFormOpeningOnStartingApplication.OpenByDefault IS NULL 
	|			THEN FALSE
	|		ELSE ConfigureFormOpeningOnStartingApplication.OpenByDefault
	|	END AS OpenByDefault
	|FROM
	|	Enum.FormsOpenedOnApplicationStart AS FormsOpenedOnApplicationStart
	|		LEFT JOIN InformationRegister.ConfigureFormOpeningOnStartingApplication AS ConfigureFormOpeningOnStartingApplication
	|		ON FormsOpenedOnApplicationStart.Ref = ConfigureFormOpeningOnStartingApplication.OpenedForm
	|			AND (ConfigureFormOpeningOnStartingApplication.User = &User)";
	
	Query.SetParameter("User", Users.AuthorizedUser());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		StructureOfFormParameters = OpenFormsOnApplicationStartClientServerOverridable.FormSettings(Selection.OpenedForm);
		
		StructureOfFormParameters.Insert("SettingsAreSet", Selection.SettingsAreSet);
		StructureOfFormParameters.Insert("Parameters",            New Structure);
		StructureOfFormParameters.Insert("OpenByDefault", Selection.OpenByDefault);
		
		If Selection.SettingsAreSet Then
			
			Selection_Parameters = Selection.Parameters; // ValueStorage
			Parameters = Selection_Parameters.Get();
			If TypeOf(Parameters) = Type("Structure") Then
				StructureOfFormParameters.Insert("Parameters", Parameters);
			EndIf;
			
		EndIf;
		
		ArrayOfFormsToOpen.Add(StructureOfFormParameters);
		
	EndDo;
	
	Return ArrayOfFormsToOpen;
	
EndFunction

// Returns an array whose elements are the values of enumerations of forms that are opened when the system starts working.
//
// Parameters:
//	ChoiceData - Undefined, ValueList - list of values of the forms to open.
//	Parameters - Undefined, Structure - the selection parameters.
//
// Returns:
//	Array - an array whose elements are the values of enumerations of forms that are opened at the start 
//		of the system.
//
Function FormsUsedWhenStartingSystem(ChoiceData = Undefined, Parameters = Undefined) Export
	
	If GetFunctionalOption("BaseVersion") Then
		
		If Parameters = Undefined Then
			// Fill in the empty parameters in the same way as the parameters of the event processing the received selection.
			// It is necessary if this procedure is called "from the outside".
			Parameters = New Structure;
			Parameters.Insert("Filter", New Structure);
			Parameters.Insert("SearchString");
		EndIf;
		
		ArrayOfExcludedValues = New Array;
		ArrayOfExcludedValues.Add(Enums.FormsOpenedOnApplicationStart.MobileWarehouseKeeperWorkspace);
		ArrayOfExcludedValues.Add(Enums.FormsOpenedOnApplicationStart.MobileWorkspaceForAssemblyAndCourierDelivery);
		ArrayOfExcludedValues.Add(Enums.FormsOpenedOnApplicationStart.PerformanceDashboard);
		ArrayOfExcludedValues.Add(Enums.FormsOpenedOnApplicationStart.WorkplaceOfWarehouseWorker);
		ArrayOfExcludedValues.Add(Enums.FormsOpenedOnApplicationStart.WorkplaceOfDeliveryOfficer);
		ArrayOfExcludedValues.Add(Enums.FormsOpenedOnApplicationStart.SalesWizard);
		
		TMCommonUse.SelectableEnumerationValues(
			"FormsOpenedOnApplicationStart",
			ChoiceData,
			Parameters,
			ArrayOfExcludedValues);
		
		Result = ChoiceData.UnloadValues();
		
	Else
		
		Result = New Array;
		For Each EnumerationValue In Enums.FormsOpenedOnApplicationStart Do
			Result.Add(EnumerationValue);
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
