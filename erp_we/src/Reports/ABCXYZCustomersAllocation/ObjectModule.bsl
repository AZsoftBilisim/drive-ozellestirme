#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm             - ClientApplicationForm - report form.
//   Cancel                - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	Parameters = ThisForm.Parameters;
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	
	If Not (Parameters.Property("Details") And Parameters.Details = Undefined) Then
		DetailsParameters = Parameters.Details;
		UsedSettings = FormSettingsComposer.FixedSettings;
		
		If TypeOf(DetailsParameters) = Type("DataCompositionDetailsProcessDescription") Then
			DCSSettings  = GetFromTempStorage(DetailsParameters.Data).Settings;
			CurrentPeriod = DataCompositionClientServer.GetParameter(DCSSettings, "CurrentPeriod").Value;
			ClassificationParameterType = DataCompositionClientServer.GetParameter(DCSSettings, "ClassificationParameterType").Value;
		Else
			// To set the selection
			FilterDecryptions = UsedSettings.Filter;
			If DetailsParameters.Property("Questions") Then
				FieldXYZ = New DataCompositionField("XYZClass");
				FieldABC = New DataCompositionField("ABCClass");

				SelectionGroupDoesNot = CreateSelectionGroup(FilterDecryptions, DataCompositionFilterItemsGroupType.NotGroup);
				SelectionGroupOr = CreateSelectionGroup(SelectionGroupDoesNot, DataCompositionFilterItemsGroupType.OrGroup);
				SelectionGroupAnd = CreateSelectionGroup(SelectionGroupOr, DataCompositionFilterItemsGroupType.AndGroup);
				CreateSelectionItem(SelectionGroupAnd, FieldABC, Enums.ABCClassification.AClass);
				SelectionGroupOrXYZ = CreateSelectionGroup(SelectionGroupAnd, DataCompositionFilterItemsGroupType.OrGroup);
				CreateSelectionItem(SelectionGroupOrXYZ, FieldXYZ, Enums.XYZClassification.XClass);
				CreateSelectionItem(SelectionGroupOrXYZ, FieldXYZ, Enums.XYZClassification.ZClass);
				SelectionGroupAnd = CreateSelectionGroup(SelectionGroupOr, DataCompositionFilterItemsGroupType.AndGroup);
				CreateSelectionItem(SelectionGroupAnd, FieldABC, Enums.ABCClassification.CClass);
				CreateSelectionItem(SelectionGroupAnd, FieldXYZ, Enums.XYZClassification.XClass);
				CreateSelectionItem(SelectionGroupOr, FieldXYZ, Enums.XYZClassification.NotClassified);
				CreateSelectionItem(SelectionGroupOr, FieldXYZ, Enums.XYZClassification.EmptyRef());
			Else
				For Each Item In DetailsParameters.Filter Do
					CreateSelectionItem(FilterDecryptions, 
						New DataCompositionField(Item.Key), 
						Item.Value);
				EndDo;
			EndIf;
			DetailsParameters.Insert("UsedSettings", UsedSettings);
			
			CurrentPeriod             = DetailsParameters.CurrentPeriod;
			ClassificationParameterType = DetailsParameters.ClassificationParameterType;
		EndIf;
		
		// To set the data parameters
		DataCompositionClientServer.SetParameter(UsedSettings, "CurrentPeriod", CurrentPeriod);
		DataCompositionClientServer.SetParameter(UsedSettings, "ClassificationParameterType", ClassificationParameterType);
		
	EndIf;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm             - ClientApplicationForm - report form.
//   NewDCSettings     - DataCompositionSettings - passed from the handler parameters "as is".
//
Procedure OnLoadUserSettingsAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	Parameters = ThisForm.Parameters;

	If Not Parameters.Property("Details") 
		Or TypeOf(Parameters.Details) <> Type("Structure") Then
		Return;
	EndIf;
	
	// To install the headers
	DetailsParameters = Parameters.Details; // Structure - 
	Settings = Report.SettingsComposer.Settings; // DataCompositionSettings 
	Settings.OutputParameters.SetParameterValue("Title", DetailsParameters.Title);
	Selection = Settings.Selection.Items;
	ParameterTypeField = New DataCompositionField("ClassificationParameterValue");
	For Each Item In Selection Do
		If Item.Field = ParameterTypeField Then
			Item.Title = DetailsParameters.ClassificationParameterType;
		EndIf;
	EndDo;
	
	// If there is a Decryption, the Selection and Data Parameters will get into the Settings from the Fixed Settings
	For Each Parameter In Settings.DataParameters.Items Do
		Parameter.Value = Undefined;
		Parameter.Use = False;
	EndDo;
	Settings.Filter.Items.Clear();
	
EndProcedure

#EndRegion

#Region Private

// Creates a data layout selection group.
// 
// Parameters:
// 	Parent  - DataCompositionFilterItemGroup    - parent of the group being created.
// 	GroupType - DataCompositionFilterItemsGroupType - type of group to create.
// Returns:
//   DataCompositionFilterItemGroup - the created group.
//
Function CreateSelectionGroup(Parent, GroupType)
	
	FilterGroup = Parent.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = GroupType;
	FilterGroup.Use = True;
	
	Return FilterGroup;
EndFunction

// Creates an element for the selection of data layout.
// 
// Parameters:
// 	Parent  - DataCompositionFilterItemGroup    - parent of the group being created.
// 	Field      - String - the left value selection.
// 	Value  - Arbitrary - the right selection value.
//
Procedure CreateSelectionItem(Parent, Field, Value)
	
	FilterElement = Parent.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = Field;
	FilterElement.RightValue = Value;
	FilterElement.Use  = True;
	
EndProcedure

#EndRegion

#EndIf