///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called in the same-name event handler after executing the report form code.
// See "ReportsClientOverridable.CommandHandler" and "ClientApplicationForm.OnCreateAtServer" in Syntax Assistant.
//
// Parameters:
//   Form - ClientApplicationForm - Report form.
//         - ManagedFormExtensionForReports
//         - Structure:
//           * ReportSettings - See ReportsClientServer.DefaultReportSettings
//   Cancel - Boolean - Flag indicating that the form creation is canceled.
//   StandardProcessing - Boolean - Flag indicating whether standard (system) event processing is executed.
//
// Example:
//	Add a command with a handler to ReportsClientOverridable.CommandHandler:
//	Command = ReportForm.Commands.Add("MySpecialCommand");
//	Command.Action = Attachable_Command;
//	Command.Header = NStr("en = 'My command…'; fa = 'My command…'");
//	
//	Button = ReportForm.Items.Add(Command.Name, Type("FormButton"), ReportForm.Items.<SubmenuName>);
//	Button.CommandName = Command.Name;
//	
//	ReportForm.ConstantCommands.Add(CreateCommand.Name);
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	ReportsTMOverridable.OnCreateAtServer(Form, Cancel, StandardProcessing);
EndProcedure

// Called in the event handler of the report form and the report settings form.
// See "Client application form extension for reports.BeforeLoadVariantAtServer" in Syntax Assistant.
//
// Parameters:
//   Form - ClientApplicationForm - Report form or a report settings form.
//   NewDCSettings - DataCompositionSettings - Settings to load into the Settings Composer.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	ReportsTMOverridable.BeforeLoadVariantAtServer(Form, NewDCSettings);
EndProcedure

// Called in the report form and report settings form before displaying the setting 
// for specifying additional choice parameters.
// Obsolete, use the AfterLoadSettingsInLinker event of the report module instead.
// 
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForReports
//        - Undefined - Report form.
//  SettingProperties - Structure - Details of the report setting to be displayed in the report form, where::
//      * DCField - DataCompositionField - Setting to be output.
//      * TypeDescription - TypeDescription - Type of a setting to be output.
//      * ValuesForSelection - ValueList - Objects to be prompted to a user in the choice list.
//                            The parameter adds items to the list of objects previously selected by a user.
//                            Note: Do not assign new value lists to this parameter.
//      * SelectionValuesQuery - Query - Query to obtain objects to be added to ValuesForSelection. 
//                               As the first column (with 0 index), select the object,
//                               that has to be added to the ValuesForSelection.Value.
//                               To disable autofilling, assign the SelectionValuesQuery.Text property
//                               to a blank string.
//      * RestrictSelectionBySpecifiedValues - Boolean - Pass True to restrict user selection
//                                                with values specified in ValuesForSelection (its final state).
//      * Type - String
//
// Example:
//   1. For all CatalogRef.Users settings, hide and do not allow selecting users marked for deletion, 
//   inactive users, and utility users.
//
//   If SettingProperties.TypeDescription.ContainsType(Type("CatalogRef.Users")) Then
//     SettingProperties.RestrictSelectionBySpecifiedValues = True;
//     SettingProperties.ValuesForSelection.Clear();
//     SettingProperties.SelectionValuesQuery.Text =
//       "SELECT Ref FROM Catalog.Users
//       |WHERE NOT DeletionMark AND NOT Invalid AND NOT IsInternal";
//   EndIf;
//
//   2. Provide an additional value for selection for the Size setting.
//
//   If SettingProperties.DCField = New DataCompositionField("DataParameters.Size") Then
//     SettingProperties.ValuesForSelection.Add(10000000, NStr("en = 'Over 10 MB'; fa = 'Over 10 MB'"));
//   EndIf;
//
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	ReportsTMOverridable.OnDefineSelectionParameters(Form, SettingProperties);     
EndProcedure

// Allows to set a list of frequently used fields displayed in the submenu for context menu commands 
// "Insert field to the left", "Insert grouping below", etc.  
//
// Parameters:
//   Form - ClientApplicationForm - Report form.
//   MainField - Array of String - Names of the most frequently used report fields.
//
Procedure WhenDefiningTheMainFields(Form, MainField) Export 
	
	
	
EndProcedure

// This procedure should describe additional dependencies
// of configuration metadata objects that will be used to link report settings.
//
// Parameters:
//   MetadataObjectsLinks - ValueTable:
//       * SubordinateAttribute - String - name of the detail of the subordinate metadata object.
//       * SubordinatedType      - Type    - type of the subordinate metadata object.
//       * MasterType          - Type    - type of the leading metadata object.
//
Procedure AddMetadataObjectsConnections(MetadataObjectsLinks) Export
	ReportsTMOverridable.AddMetadataObjectsConnections(MetadataObjectsLinks);
EndProcedure

#EndRegion