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
	
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  NewDCSettings - DataCompositionSettings - 
//
Procedure OnLoadVariantAtServer(Form, NewDCSettings) Export
	
	RemoveAssignmentFromLayoutSettings(Form);
	
	ProcessType = Common.ObjectAttributeValue(
		Form.Parameters.CommandParameter,
		"ProductionProcessType");
	
	DataCompositionClientServer.SetParameter(
		SettingsComposer,
		"ThisIsDisassembly",
		ProcessType = Enums.ProductionProcessTypes.Disassembly,
		True);
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//  Form - See ReportsOverridable.OnCreateAtServer.Form
//  Cancel - See ReportsOverridable.OnCreateAtServer.Cancel
//  StandardProcessing - See ReportsOverridable.OnCreateAtServer.StandardProcessing
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	FillFilterParameters(Form);
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
Procedure OnLoadUserSettingsAtServer(Form, NewDCUserSettings) Export
	
	RemoveAssignmentFromLayoutSettings(Form);
	
EndProcedure

#EndRegion

#Region Private

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

Procedure FillFilterParameters(Form)
	
	If Not Form.Parameters.Property("CommandParameter") Or Not ValueIsFilled(Form.Parameters.CommandParameter) Then
		MessageText = NStr("vi = 'Không hỗ trợ mở trực tiếp báo cáo ""Kế hoạch sản xuất thành phẩm và bán thành phẩm"". 
			|Để mở báo cáo, có thể sử dụng lệnh ""Kế hoạch sản xuất thành phẩm và bán thành phẩm"" trong biểu mẫu chứng từ.';
			|ru = 'Непосредственное открытие отчета ""План производства продукции и полуфабрикатов"" не предусмотрено. 
			|Для открытия отчета можно воспользоваться командой ""План производства продукции и полуфабрикатов"" в формах документов.';
			|en = 'Direct opening of the ""Production plan for products and semi-finished products"" report is not provided. 
			|To open the report, click ""Production plan for products and semi-finished products"" in the document forms.'; fa = 'Direct opening of the ""Production plan for products and semi-finished products"" report is not provided. 
			|To open the report, click ""Production plan for products and semi-finished products"" in the document forms.';
			|it = 'Non è prevista l''apertura diretta del report ""Piano di produzione di articoli e semilavorati"". 
			|Per aprire il report è possibile utilizzare il comando ""Piano di produzione di articoli e semilavorati"" nei moduli dei documenti.';
			|pl = 'Bezpośrednie otwarcie raportu ""Plan wyprodukowania produkcji i półproduktów"" nie jest przewidziane. 
			|W celu otwarcia raportu można skorzystać z polecenia ""Plan wyprodukowania produkcji i półproduktów"" w formularzach dokumentów.';
			|tr = '""İmal edilen ürünler ve yarı mamul ürünlerin üretim planı"" raporu açılması sağlanamadı. 
			|Raporun açılması için belge formunda yer alan ""İmal edilen ürünler ve yarı mamul ürünler üretim planı"" komutundan faydalanabilirsiniz.'");
		Raise MessageText;
	EndIf;

	Form.ParametersForm.Filter.Insert("ProductionPlan", Form.Parameters.CommandParameter);
	
EndProcedure

Procedure RemoveAssignmentFromLayoutSettings(Form)
	
	If Common.ObjectAttributeValue(
		Form.Parameters.CommandParameter, "Scenario.PlanningByAssignments") Then
		Return;
	EndIf;
	
	Settings = SettingsComposer.Settings;
	
	DestinationField_ = New DataCompositionField("Purpose");
	MatchingElements = New Map;
	
	FindGroupingRecursively(Settings.Structure, MatchingElements, DestinationField_);
	For Each Group In MatchingElements Do
		
		GroupingKey = Group.Key; // DataCompositionGroup, DataCompositionTableGroup
		
		If GroupingKey.GroupFields.Items.Count() = 1 Then
			GroupingKey.Parent.Structure.Delete(Group.Key);
		Else
			GroupingKey.GroupFields.Items.Delete(Group.Value);
		EndIf;
		
		DeleteSelectedField(GroupingKey.Selection, DestinationField_, Settings);
		
	EndDo;
	
	DataCompositionServer.RemoveSelectionItemFromAllReportSettings(Settings, "Purpose");
	
EndProcedure

Procedure FindGroupingRecursively(ItemsCollection, MatchingElements, SearchValue)
	
	For Each Item In ItemsCollection Do
		
		If TypeOf(Item) = Type("DataCompositionGroup")
			Or TypeOf(Item) = Type("DataCompositionTableGroup") Then
			For Each GroupingField In Item.GroupFields.Items Do 
				If GroupingField.Field = SearchValue Then
					MatchingElements.Insert(Item, GroupingField)
				EndIf;
			EndDo;
			FindGroupingRecursively(Item.Structure, MatchingElements, SearchValue);
		ElsIf TypeOf(Item) = Type("DataCompositionTable") Then
			FindGroupingRecursively(Item.Rows, MatchingElements, SearchValue);
			FindGroupingRecursively(Item.Columns, MatchingElements, SearchValue);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure DeleteSelectedField(SelectedFields, SearchValue, Settings)
	
	ItemArray = New Array; // Array of DataCompositionSelectedField
	
	FindSelectedFieldRecursively(SelectedFields.Items, ItemArray, SearchValue);
	For Each Item In ItemArray Do
		
		IDOfElementSCustomSetting = Settings.Selection.GetIDByObject(Item);;
		If Item.Parent <> Undefined Then
			Item.Parent.Items.Delete(Item);
		Else
			SelectedFields.Items.Delete(Item);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FindSelectedFieldRecursively(ItemsCollection, ItemArray, SearchValue)

	For Each Item In ItemsCollection Do
		
		If TypeOf(Item) = Type("DataCompositionSelectedField") Then
			If Item.Field = SearchValue Then
				ItemArray.Add(Item);
			EndIf;
		ElsIf TypeOf(Item) = Type("DataCompositionAutoSelectedField") Then
			Continue;
		Else
			FindSelectedFieldRecursively(Item.Items, ItemArray, SearchValue);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
