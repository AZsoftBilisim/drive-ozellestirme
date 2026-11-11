#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	DataCompositionClientServer.SetParameter(SettingsComposer, "BlankID", CommonClientServer.BlankUUID());

	SurplusScheme = DataCompositionSchema.NestedDataCompositionSchema.Section1_IsolatedSurplus; // NestedDataCompositionSchema
	SetOfSurplus = SurplusScheme.Schema.DataSets.IsolatedSurplus;
	SchemeIsInOperation = DataCompositionSchema.NestedDataCompositionSchema.Section2_INWork; // NestedDataCompositionSchema
	SetSurplusDeficit = SchemeIsInOperation.Schema.DataSets.Surplus_Deficit;
	
	QueryText = SetOfSurplus.Query;
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Result = "SubstitutionInventoryAllocation"; // @query-part-1
	
	ProvisionInDocumentsServer.InventoryAllocation(QueryText, TablesNames);
	SetOfSurplus.Query = QueryText;
	
	QueryText = SetSurplusDeficit.Query;
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Result = "SubstitutionInventoryAllocation"; // @query-part-1
	
	ProvisionInDocumentsServer.InventoryAllocation(QueryText, TablesNames);
	SetSurplusDeficit.Query = QueryText;
	
	ProductionOrder = DataCompositionClientServer.GetParameter(SettingsComposer, "ProductionOrder").Value;
	Assignments = GetOrderAssignments(ProductionOrder);
	ThereAreAppointments = Not Assignments.Count() = 0;
	
	OnlySurplus = DataCompositionClientServer.GetParameter(SettingsComposer, "OnlySurplus").Value;
	ExceedingOrder = DataCompositionClientServer.GetParameter(SettingsComposer, "ExceedingOrder").Value;
	Products = DataCompositionClientServer.GetParameter(SettingsComposer, "Products");
	
	AllWarehousesAreAvailable = AllWarehousesAreAvailable();
	
	If Not AllWarehousesAreAvailable Then
		
		SurplusField = SetOfSurplus.Fields.Find("Surplus"); // DataCompositionSchemaDataSetField
		SurplusField.Title = NStr("vi = 'Hàng thừa (trong kho khả dụng)';
									|ru = 'Излишек (на доступных складах)';
									|en = 'Surplus (in available warehouses)'; fa = 'Surplus (in available warehouses)';
									|it = 'Surplus (in available warehouses)';
									|pl = 'Surplus (in available warehouses)';
									|tr = 'Fazlalık (mevcut ambarlarda)'");
		
		SurplusDeficitScheme = DataCompositionSchema.NestedDataCompositionSchema.Section2_INWork; // NestedDataCompositionSchema
		SetSurplusDeficit = SurplusDeficitScheme.Schema.DataSets.Surplus_Deficit;
		
		SurplusDeficitField = SetSurplusDeficit.Fields.Find("Surplus"); // DataCompositionSchemaDataSetField
		SurplusDeficitField.Title = NStr("vi = 'Hàng thừa (trong kho khả dụng)';
										|ru = 'Излишек (на доступных складах)';
										|en = 'Surplus (in available warehouses)'; fa = 'Surplus (in available warehouses)';
										|it = 'Surplus (in available warehouses)';
										|pl = 'Surplus (in available warehouses)';
										|tr = 'Fazlalık (mevcut ambarlarda)'");
		
		SurplusDeficitField = SetSurplusDeficit.Fields.Find("Deficit"); // DataCompositionSchemaDataSetField
		SurplusDeficitField.Title = NStr("vi = 'Thâm hụt (trong kho khả dụng)';
										|ru = 'Дефицит (на доступных складах)';
										|en = 'Shortage (in available warehouses)'; fa = 'Shortage (in available warehouses)';
										|it = 'Shortage (in available warehouses)';
										|pl = 'Shortage (in available warehouses)';
										|tr = 'Miktar açığı (mevcut ambarlarda)'");
		
	EndIf;
	
	For Each Group In SettingsComposer.Settings.Structure Do
		DataCompositionClientServer.SetParameter(Group.Settings, "Products", Products.Value, Products.Use);
		If Group.Name = "IsolatedSurplus" Then
			DataCompositionClientServer.SetParameter(Group.Settings, "Assignments", Assignments, True);
			DataCompositionClientServer.SetParameter(Group.Settings, "ThereAreAppointments", ThereAreAppointments);
			Group.Use = ThereAreAppointments;
		ElsIf Group.Name = "InProgress" Then
			If OnlySurplus Then
				DataCompositionClientServer.AddFilter(Group.Settings.Filter, "Surplus", 0, DataCompositionComparisonType.Greater);
			Else
				DataCompositionClientServer.DeleteSelection(Group.Settings.Filter, "Surplus");
			EndIf;
			If ExceedingOrder And Group.Settings.Structure.Count() > 0 Then
				DataCompositionClientServer.AddFilter(Group.Settings.Structure[0].Filter, "ExceedingOrder", 0, DataCompositionComparisonType.Greater);
			Else
				DataCompositionClientServer.DeleteSelection(Group.Settings.Structure[0].Filter, "ExceedingOrder");
			EndIf;
		ElsIf Group.Name = "Manufactured" Then
			Group.Use = Not OnlySurplus;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	Parameters = ThisForm.Parameters;
	If Parameters.Property("CommandParameter") And TypeOf(Parameters.CommandParameter) = Type(
		"DocumentRef.ProductionOrder2_2") Then
		ThisForm.ParametersForm.Filter.Insert("ProductionOrder", Parameters.CommandParameter);
	EndIf;
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
// Parameters:
//   Context - Arbitrary - 
//       Parameters of the context in which the report is used.
//       Used for passing the ReportServer method parameters.Connect the circuit().
//   SchemaKey - String -
//       ID of the current configuration Builder schema.
//       By default, it is empty (this means that the linker is initialized based on the main schema).
//       Used for optimization to reinitialize the linker as rarely as possible).
//       It may not be used if reinitialization is performed unconditionally.
//   VariantKey - String, Undefined -
//       Name of the predefined or unique ID of the custom version of the report.
//       Undefined when calling for a decryption option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Builder after it is initialized.
//       Undefined when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the settings builder after its initialization.
//       It is uncertain when the user settings do not need to be loaded (already loaded earlier).
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	Parameter_Order = NewDCSettings.DataParameters.Items.Find("ProductionOrder");
	
	If Parameter_Order <> Undefined And ValueIsFilled(Parameter_Order.Value)
		And Common.ObjectAttributeValue(Parameter_Order.Value, "ProductionProcessType") = Enums.ProductionProcessTypes.Disassembly Then
		
		DataCompositionSchema.Parameters.ShowSideIssue.UseRestriction = True;
		ParameterIsSideIssue = NewDCSettings.DataParameters.Items.Find("ShowSideIssue");
		ParameterIsSideIssue.Value = True;
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function GetOrderAssignments(ProductionOrder)
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Assignments.Ref AS Purpose
	|FROM
	|	Catalog.Assignments AS Assignments
	|WHERE
	|	Assignments.Ref IN
	|		(SELECT
	|			ProductionOrder2_2.Purpose AS Purpose
	|		FROM
	|			Document.ProductionOrder2_2 AS ProductionOrder2_2
	|		WHERE
	|			ProductionOrder2_2.Ref = &ProductionOrder
	|
	|		UNION
	|
	|		SELECT
	|			ProductionOrder2_2.AssignmentProducts
	|		FROM
	|			Document.ProductionOrder2_2 AS ProductionOrder2_2
	|		WHERE
	|			ProductionOrder2_2.Ref = &ProductionOrder
	|			AND NOT ProductionOrder2_2.AssignmentProducts = VALUE(Catalog.Assignments.EmptyRef)
	|
	|		UNION
	|
	|		SELECT DISTINCT
	|			ProductionOrder2_2ManufacturedProduct.Purpose
	|		FROM
	|			Document.ProductionOrder2_2.ManufacturedProduct AS ProductionOrder2_2ManufacturedProduct
	|		WHERE
	|			ProductionOrder2_2ManufacturedProduct.Ref = &ProductionOrder
	|			AND NOT ProductionOrder2_2ManufacturedProduct.Purpose = VALUE(Catalog.Assignments.EmptyRef))
	|	AND Assignments.OrderDocument <> UNDEFINED";

	Query.SetParameter("ProductionOrder", ProductionOrder);
	Return Query.Execute().Unload().UnloadColumn("Purpose");
EndFunction

Function AllWarehousesAreAvailable()
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(Warehouses.Ref) AS Count
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	NOT Warehouses.IsFolder";
	
	Selection = Query.Execute().Select();
	Selection.Next();
	TotalWarehouses_ = Selection.Count;
	
	SetPrivilegedMode(False);
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(Warehouses.Ref) AS Count
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	NOT Warehouses.IsFolder";
	
	Selection = Query.Execute().Select();
	Selection.Next();
	WarehousesAreAvailable = Selection.Count;
	
	Return TotalWarehouses_ = WarehousesAreAvailable;
	
EndFunction

#EndRegion

#EndIf
