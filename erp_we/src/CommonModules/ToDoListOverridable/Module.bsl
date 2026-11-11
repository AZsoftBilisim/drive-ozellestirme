///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Determines a list of handlers (manager modules or common modules) that generate and update
// the list of all to-do items available in the configuration.
//
// In the specified modules, there must be a handler procedure the parameter is passed to
// ToDoList - See ToDoListServer.ToDoList.
// 
// The following is an example of a handler procedure for copying to the specified modules
//
//Parameters:
//ToDoList - See ToDoListServer.ToDoList.
////
//
//
//Procedure OnFillToDoList(ToDoList) Export
// EndProcedure
//
// Parameters:
//  ToDoList - Array - manager modules or common modules,
//                         for example: Documents.SalesOrder, SalesToDoList.
// Example:
//  ToDoList.Add(Documents.SalesOrder);
//
Procedure OnDetermineToDoListHandlers(ToDoList) Export
	
	
	ToDoListTM.OnDetermineToDoListHandlers(ToDoList);
	ToDoListLocalization.OnDetermineToDoListHandlers(ToDoList);
	
EndProcedure

// Sets the default order of sections in the to-do list panel.
//
// Parameters:
//  Sections - Array - an array of command interface sections.
//                     Sections in the To-do list panel are shown in
//                     the order in which they were added to the array.
//
Procedure OnDetermineCommandInterfaceSectionsOrder(Sections) Export
	
	Sections.Add(Metadata.Subsystems.CRMAndMarketing);
	Sections.Add(Metadata.Subsystems.Sales);
	Sections.Add(Metadata.Subsystems.Purchases);
	Sections.Add(Metadata.Subsystems.Warehouse);
	Sections.Add(Metadata.Subsystems.Production);
	If Metadata.Subsystems.Find("Salary") <> Undefined Then
		Sections.Add(Metadata.Subsystems["Salary"]);
	EndIf;
	If Metadata.Subsystems.Find("Frames") <> Undefined Then
		Sections.Add(Metadata.Subsystems["Frames"]);
	EndIf;
	Sections.Add(Metadata.Subsystems.TreasuryAndARAPAccounting);
	
	Subsystem = Planning.SubsystemPlanning();
	If Subsystem <> Undefined Then
		Sections.Add(Subsystem);
	EndIf;
	If Metadata.Subsystems.Find("LocalAccounting") <> Undefined Then
		Sections.Add(Metadata.Subsystems["LocalAccounting"]);
	EndIf;
	If Metadata.Subsystems.Find("InternationalFinancialAccounting") <> Undefined Then
		Sections.Add(Metadata.Subsystems["InternationalFinancialAccounting"]);
	EndIf;
	Sections.Add(Metadata.Subsystems.FinancialResultAndControlling);
	
	Sections.Add(Metadata.Subsystems.Administration);
	
EndProcedure

// Defines to-do items that are hidden from a user.
//
// Parameters:
//  ToDoItemsToDisable - Array - an array of strings IDs of to-do items to disable.
//
Procedure OnDisableToDos(ToDoItemsToDisable) Export
	
EndProcedure

// It allows you to change some subsystem settings.
//
// Parameters:
//  Parameters - Structure:
//     * OtherToDoItemsTitle - String - a title of a section that displays
//                            to-do items not included in any command interface sections.
//                            It is applicable to to-do items whose positions in the panel
//                            are determined by the ToDoListServer.SectionsForObject function.
//                            If this parameter is not specified, to-do items are displayed as a group named
//                            Other to dos.
//
Procedure OnDefineSettings(Parameters) Export
	
	
	
EndProcedure

// Helps to set query parameters that are common for several to-do items.
//
// For example, if several handlers of getting to-do items have
// the CurrentDate parameter, you can add the algorithm that sets the parameter to this
// procedure and then call the
// ToDoList.SetCommonQueryParameters() procedure to set the parameter.
//
// Parameters:
//  Query - Query - a running query.
//  CommonQueryParameters - Structure - common values for calculating to-do items.
//
Procedure SetCommonQueryParameters(Query, CommonQueryParameters) Export
	
	Query.SetParameter("UpdateDate", BegOfDay(CommonQueryParameters.CurrentDate));
	
EndProcedure

// A handler procedure that can be called in to-do transcript forms
// to redefine the parameters for opening the form and setting the necessary selections in the form lists.
//
// Parameters:
//  Form  - ClientApplicationForm - the form from which the method was called.
//  List - DynamicList - a list whose parameters can be redefined.
//
Procedure OnCreateAtServer(Form, List) Export
	Var QuickFilterStructure;
	Var CurrentPageName;
	
	// Fill in the structure of the form details
	AttributesStructure1 = New Structure;
	For Each Attribute In Form.GetAttributes() Do
		AttributesStructure1.Insert(Attribute.Name);
	EndDo;
	
	If Form.Parameters.Property("QuickFilterStructure", QuickFilterStructure) Then
		
		For Each KeyAndValue In QuickFilterStructure Do
			
			If AttributesStructure1.Property(KeyAndValue.Key) Then
				
				// The selection element of the dynamic list is displayed on the form
				ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
					List,
					KeyAndValue.Key,
					Form[KeyAndValue.Key],
					QuickFilterStructure);
				
			Else
				
				// The selection is performed directly in the properties of the dynamic list
				CommonClientServer.SetDynamicListFilterItem(
					List,
					KeyAndValue.Key,
					KeyAndValue.Value,
					DataCompositionComparisonType.Equal,
					,
					True);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// Setting the current form element
	If Form.Parameters.Property("CurrentPageName", CurrentPageName) Then
		Form.CurrentItem = Form.Items[CurrentPageName];
	EndIf;
	
EndProcedure

// A handler procedure that can be called in the corresponding
// to-do transcript form handler to replace the saved form details values.
//
// Parameters:
//  Form - ClientApplicationForm - the form from which the method was called.
//  Settings - Map - form settings, which are the values of the requisites.
//
Procedure BeforeLoadDataFromSettingsAtServer(Form, Settings) Export
	Var QuickFilterStructure;
	
	If Form.Parameters.Property("QuickFilterStructure", QuickFilterStructure) Then
		
		For Each KeyAndValue In QuickFilterStructure Do
			
			SettingValue = Settings.Get(KeyAndValue.Key);
			
			// If there is a saved value of the form's props and it does not match the value
			// from the Quick Selection structure, then replace the saved value with the value of quick selection.
			If SettingValue <> Undefined And SettingValue <> KeyAndValue.Value Then
				Settings.Insert(KeyAndValue.Key, KeyAndValue.Value);
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion