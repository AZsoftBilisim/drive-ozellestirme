
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FilterAll = True;
	
	Items.FormToIssueQualityControlCertificate.Enabled = AccessRight("Insert",
		Metadata.Documents.GoodsQualityControlCertificate);
	
	InitializeCache();
	RestoreFormSettingsWhenCreating();
	
	#Region UniversalMechanisms
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	SaveFormSettings();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ControlRequestsClick(Item)
	OpenForm("Document.RequestForGoodsQualityControl.Form.FulfillmentOfResearchRequests");
EndProcedure

&AtClient
Procedure QualityControlCertificatesClick(Item)
	OpenForm("Document.GoodsQualityControlCertificate.Form.ListForm");
EndProcedure

&AtClient
Procedure HyperlinkAllClick(Item)
	Clear_Filter();
EndProcedure

&AtClient
Procedure HyperlinkToStudyClick(Item)
	
	FilterCompleted = False;
	FilterOnResearch = True;
	FilterAll = False;
	
	EstablishSelectionOnResearch(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure HyperlinkCompletedClick(Item)
	
	FilterCompleted = True;
	FilterOnResearch = False;
	FilterAll = False;
	EstablishSelectionOnResearch(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Filter");

EndProcedure

&AtClient
Procedure HyperlinkWithoutDeviationsClick(Item)
	
	SelectionWithoutDeviations = True;
	FilterWithVariances = False;
	FilterAll = False;
	
	SetSelectionWithoutDeviations(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure HyperlinkWithDeviationsClick(Item)
	
	SelectionWithoutDeviations = False;
	FilterWithVariances = True;
	FilterAll = False;
	
	SetSelectionWithDeviations(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	SetSelectionItem();
	
	FilterAll = False;
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure FilterRequestForControlOnChange(Item)
	
	SetSelectionControlRequest(ThisObject);
	
	FilterAll = False;
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure FilterGoodsResearchSheetOnChange(Item)
	
	SetSelectionGoodsResearchMap(ThisObject);
	
	FilterAll = False;
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	SetSelectionResponsible(ThisObject);
	
	FilterAll = False;
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	Template = NStr("vi = '%1 %2 %3';
					|ru = '%1 %2 %3';
					|en = '%1 %2 %3'; fa = '%1 %2 %3';
					|it = '%1 %2 %3';
					|pl = '%1 %2 %3';
					|tr = '%1 %2 %3'");
	Template2 = NStr("vi = '%1 và hơn nữa %2';
					|ru = '%1 и еще %2';
					|en = '%1 and %2 more'; fa = '%1 and %2 more';
					|it = '%1 and %2 more';
					|pl = '%1 and %2 more';
					|tr = '%1 ve %2 tane daha '");
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	GoodsQualityResearchPlanAndResearchResult.Ref AS Ref,
		|	GoodsQualityResearchPlanAndResearchResult.Products,
		|	GoodsQualityResearchPlanAndResearchResult.Characteristic,
		|	GoodsQualityResearchPlanAndResearchResult.Series,
		|	GoodsQualityResearchPlanAndResearchResult.Purpose
		|FROM
		|	Document.GoodsQualityResearch.PlanAndResearchResult AS
		|		GoodsQualityResearchPlanAndResearchResult
		|WHERE
		|	GoodsQualityResearchPlanAndResearchResult.Ref IN (&References)
		|TOTALS
		|BY
		|	Ref";
	
	Query.SetParameter("References", Rows.GetKeys());
	QueryResult = Query.Execute();
	
	FetchLink = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While FetchLink.Next() Do
		
		FirstPosition = True;
		NumberOfRows = 1;
		SelectionDetailRecords = FetchLink.Select();
	
		While SelectionDetailRecords.Next() Do
			If FirstPosition Then
				FirstPosition = False;
				Presentation = ProductsClientServer.ProductPresentation(SelectionDetailRecords.Products,
					SelectionDetailRecords.Characteristic, , SelectionDetailRecords.Series, SelectionDetailRecords.Purpose);
			Else
				NumberOfRows = NumberOfRows + 1;
			EndIf;
		EndDo;
		
		ListLine = Rows[FetchLink.Ref];
		If NumberOfRows > 1 Then
			PresentationNumberOfPositions = GetStringDeclensionsByNumber("position", NumberOfRows-1,
				"","NM=Cardinal", "CS=Nominative; NP=Number");
			ListLine.Data["OwnGoods"] = StringFunctionsClientServer.SubstituteParametersToString(Template2, TrimAll(Presentation), PresentationNumberOfPositions[0]);
		Else
			ListLine.Data["OwnGoods"] = Presentation;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IssueQualityControlReport(Command)
	
	FormParameters = GetParametersOfQualityControlReportForm();
	
	If FormParameters <> Undefined Then
		OpenForm("Document.GoodsQualityControlCertificate.Form.DocumentForm", FormParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region QualityControlAct

&AtClient
Function GetParametersOfQualityControlReportForm()
	
	ListOfStudies = New Array;
	
	SelectedRows = Items.List.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn dòng nào, lệnh không thể thực hiện.';
								|ru = 'Не выбраны строки, команда не может быть выполнена.';
								|en = 'No lines are selected, cannot run the command.'; fa = 'No lines are selected, cannot run the command.';
								|it = 'No lines are selected, cannot run the command.';
								|pl = 'No lines are selected, cannot run the command.';
								|tr = 'Satır seçilmedi, komut gerçekleştirilemez.'"));
		Return Undefined;
	EndIf;
	
	RowData = Items.List.RowData(Items.List.SelectedRows[0]);
	RequestForControl = RowData.RequestForControl;
	
	For Each String In SelectedRows Do

		RowData = Items.List.RowData(String);

		If RowData.RequestForControl <> RequestForControl Then
			ShowMessageBox( , NStr(
				"vi = 'Các kiểm nghiệm được chọn thuộc các guấy đề nghị kiểm soát khác nhau, lệnh không thể thực hiện.';
				|ru = 'Выбраны исследования по разным заявкам на контроль, команда не может быть выполнена.';
				|en = 'Research for different control requests is selected. Cannot run the command.'; fa = 'Research for different control requests is selected. Cannot run the command.';
				|it = 'Research for different control requests is selected. Cannot run the command.';
				|pl = 'Research for different control requests is selected. Cannot run the command.';
				|tr = 'Farklı kontrol taleplerine ait incelemeler seçildi, komut gerçekleştirilemez.'"));
			Return Undefined;
		EndIf;

		If Not RowData.Completed Then
			ShowMessageBox( , NStr("vi = 'Chưa thực hiện tất cả các kiểm nghiệm, lệnh không thể thực hiện.';
									|ru = 'Не все исследования проведены, команда не может быть выполнена.';
									|en = 'Not all the research is done. Cannot run the command.'; fa = 'Not all the research is done. Cannot run the command.';
									|it = 'Not all the research is done. Cannot run the command.';
									|pl = 'Not all the research is done. Cannot run the command.';
									|tr = 'Tüm incelemeler kaydedilmemiş, komut gerçekleştirilemez.'"));
			Return Undefined;
		EndIf;
		
		If Not RowData.Posted Then
			ShowMessageBox( , NStr("vi = 'Chưa thực hiện tất cả các kiểm nghiệm, lệnh không thể thực hiện.';
									|ru = 'Не все исследования проведены, команда не может быть выполнена.';
									|en = 'Not all the research is done. Cannot run the command.'; fa = 'Not all the research is done. Cannot run the command.';
									|it = 'Not all the research is done. Cannot run the command.';
									|pl = 'Not all the research is done. Cannot run the command.';
									|tr = 'Tüm incelemeler kaydedilmemiş, komut gerçekleştirilemez.'"));
			Return Undefined;
		EndIf;

		ListOfStudies.Add(RowData.Ref);

	EndDo;
	
	ListOfStudiesWithCompletedQualityControlCertificates = ListOfStudiesWithCompletedQualityControlCertificates(ListOfStudies, RequestForControl);
	
	ListOfStudies = CommonClientServer.ArraysDifference(ListOfStudies, ListOfStudiesWithCompletedQualityControlCertificates);
	
	If ListOfStudies.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Các biên bản kiểm soát chất lượng đã được lập cho các kiểm nghiệm đã chọn.';
								|ru = 'По выбранным исследованиям акты контроля качества уже оформлены.';
								|en = 'Quality control certificates are already issued for the selected research.'; fa = 'Quality control certificates are already issued for the selected research.';
								|it = 'Quality control certificates are already issued for the selected research.';
								|pl = 'Quality control certificates are already issued for the selected research.';
								|tr = 'Seçili incelemeler için kalite kontrol tutanakları zaten düzenlenmiş.'"));
		Return Undefined;
	EndIf;
		
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", RequestForControl);
	FillingData.Insert("AccordingToResearchDocuments", ListOfStudies);
	
	FormParameters = New Structure("Basis", FillingData);
	
	Return FormParameters;
	
EndFunction

#EndRegion

#Region Universal_

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Filters

&AtClientAtServerNoContext
Procedure SetSelectionControlRequest(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"RequestForControl",
		Form.FilterRequestForControl,
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterRequestForControl));
	
EndProcedure

&AtServer
Procedure SetSelectionItem()
	
	If ValueIsFilled(FilterProducts) Then
	
		FilterList = New ValueList;
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	T.Ref AS Ref
		|FROM
		|	Document.GoodsQualityResearch.PlanAndResearchResult AS T
		|WHERE
		|	T.Products = &Products
		|";
		Query.SetParameter("Products", FilterProducts);
		
		FilterList.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
		
	EndIf;
		
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo mặt hàng';
			|ru = 'Отбор по номенклатуре';
			|en = 'Filter by items'; fa = 'فیلتر بر اساس اقلام';
			|it = 'La selezione in base all''elenco articoli';
			|pl = 'Filtr wg pozycji';
			|tr = 'Öğeye göre filtre'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
			FilterRemainingGoodsByShelfLives,
			"Ref",
			DataCompositionComparisonType.InList,
			FilterList,
			,
			ValueIsFilled(FilterProducts));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionResponsible(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"EmployeeResponsible",
		Form.FilterEmployeeResponsible,
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterEmployeeResponsible));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionGoodsResearchMap(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"GoodsResearchSheet",
		Form.FilterGoodsResearchSheet,
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterGoodsResearchSheet));
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishSelectionOnResearch(Form)
	
	FilterOnResearch = CommonClientServer.CreateFilterItemGroup(
		Form.List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Kiểm nghiệm';
			|ru = 'Исследование';
			|en = 'Research'; fa = 'تحقیق';
			|it = 'Research';
			|pl = 'Research';
			|tr = 'İnceleme'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		FilterOnResearch,
		"Posted",
		DataCompositionComparisonType.Equal,
		True,
		,
		True);
			
	CommonClientServer.AddCompositionItem(
		FilterOnResearch,
		"Completed",
		DataCompositionComparisonType.Equal,
		Form.FilterCompleted,
		,
		True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionWithoutDeviations(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"ThereAreVariances",
		True,
		DataCompositionComparisonType.NotEqual,
		, 
		True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionWithDeviations(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"ThereAreVariances",
		True,
		DataCompositionComparisonType.Equal,
		, 
		True);
	
EndProcedure

&AtClient
Procedure Clear_Filter()
	
	FilterStructure1 = ResearchSelectionStructure();
	
	For Each Item In FilterStructure1 Do
		CommonClientServer.DeleteDynamicListFilterGroupItems(List, Item.Key); 
	EndDo;

	FilterRequestForControl			= Undefined;
	FilterProducts				= Undefined;
	FilterGoodsResearchSheet	= Undefined;
	FilterEmployeeResponsible				= Undefined;
	FilterCompleted 					= False;
	SelectionWithoutDeviations 				= False;
	FilterWithVariances 				= False;
	FilterOnResearch 			= False;
	FilterAll 						= True;
	
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Function ResearchSelectionStructure()
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("RequestForControl");
	FilterStructure1.Insert("Products");
	FilterStructure1.Insert("GoodsResearchSheet");
	FilterStructure1.Insert("EmployeeResponsible");
	FilterStructure1.Insert("Completed");
	FilterStructure1.Insert("Posted");
	FilterStructure1.Insert("ThereAreVariances");
	FilterStructure1.Insert("ResearchProject");
	
	Return FilterStructure1;
	
EndFunction

#EndRegion

#Region SettingManagement

&AtServer
Procedure RestoreFormSettingsWhenCreating()
	
	FormSettings = FormDataSettingsStorage.Load(
		ObjectKeySettingsManager(), SettingsManagerSettingsKey());
	If ValueIsFilled(FormSettings) Then
		FillPropertyValues(ThisObject, FormSettings);
	EndIf; 
	
	SetSelectionControlRequest(ThisObject);
	SetSelectionItem();
	SetSelectionGoodsResearchMap(ThisObject);
	SetSelectionResponsible(ThisObject);
	
	If FilterOnResearch Or FilterCompleted Then
		EstablishSelectionOnResearch(ThisObject);
	EndIf;
	If SelectionWithoutDeviations Then
		SetSelectionWithoutDeviations(ThisObject);
	EndIf;
	If FilterWithVariances Then
		SetSelectionWithDeviations(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveFormSettings()
	
	FormSettings = SavedFormSettings();
	
	FillPropertyValues(FormSettings, ThisObject);
	FormDataSettingsStorage.Save(
		ObjectKeySettingsManager(), SettingsManagerSettingsKey(), FormSettings);
	
EndProcedure

&AtServer
Function SavedFormSettings()
	
	Result = New Structure;
	Result.Insert("FilterRequestForControl");
	Result.Insert("FilterProducts");
	Result.Insert("FilterGoodsResearchSheet");
	Result.Insert("FilterEmployeeResponsible");
	Result.Insert("FilterAll");
	Result.Insert("FilterCompleted");
	Result.Insert("FilterOnResearch");
	Result.Insert("FilterWithVariances");
	Result.Insert("SelectionWithoutDeviations");
	
	Return Result;
	
EndFunction

&AtServer
Function ObjectKeySettingsManager()
	
	Return "Research";
	
EndFunction

&AtServer
Function SettingsManagerSettingsKey()
	
	Return "FormSettings";
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
	// highlighting the color of an overdue study
	#Region OverdueStudies
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField("DueDate_2");
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DueDate_2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = CurrentSessionDate();
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Completed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);
	
	#EndRegion
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize Or AttributesStructure1.Property("Filter") Then
		
		SetStateOfHyperlink(Form, Items.HyperlinkAll, Form.FilterAll);
		SetStateOfHyperlink(Form, Items.HyperlinkToStudy, Form.FilterOnResearch);
		SetStateOfHyperlink(Form, Items.HyperlinkCompleted, Form.FilterCompleted);
		SetStateOfHyperlink(Form, Items.HyperlinkWithoutDeviations, Form.SelectionWithoutDeviations);
		SetStateOfHyperlink(Form, Items.HyperlinkWithDeviations, Form.FilterWithVariances);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetStateOfHyperlink(Form, Item, Clicked)
	
	If Clicked Then
		Item.BackColor = Form.Cache.ColorOfPressedSelection;
	Else
		Item.BackColor = New Color();
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeCache()
	
	Cache = New Structure;
	
	Cache.Insert("ColorOfPressedSelection", StyleColors.QuickFiltersHyperlinkBackground);
	Cache.Insert("CurrentRowData", Undefined);
	
EndProcedure

&AtServer
Function ListOfStudiesWithCompletedQualityControlCertificates(ListOfStudies, RequestForControl)
	Return GoodsResearch.ListOfStudiesWithCompletedQualityControlCertificates(ListOfStudies, RequestForControl);
EndFunction

#EndRegion

#EndRegion
