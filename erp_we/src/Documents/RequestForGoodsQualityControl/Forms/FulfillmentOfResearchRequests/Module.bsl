
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FilterAll = True;
	Items.FormToAssignResearch.Enabled = AccessRight("Insert",
		Metadata.Documents.GoodsQualityResearch);
	Items.FormToIssueControlReport.Enabled = AccessRight("Insert",
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
	
	SetDynamicListProperties();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_GoodsQualityResearch"
		Or EventName = "Write_GoodsQualityControlCertificate" Then
		Items.List.Refresh();
	EndIf;
	
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
Procedure HyperlinkAllClick(Item)
	
	Clear_Filter();
	
EndProcedure

&AtClient
Procedure HyperlinkToStudyClick(Item)
	
	SelectionOfStudyIsNotAssigned = False;
	FilterOnResearch = True;
	FilterAll = False;
	
	EstablishSelectionOnResearch(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure HyperlinkNoResearchAssignedClick(Item)
	
	SelectionOfStudyIsNotAssigned = True;
	FilterOnResearch = False;
	FilterAll = False;
	SetSelectionNoResearchAssigned(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Filter");

EndProcedure

&AtClient
Procedure ClickSelectionIsOverdue(Item)
	
	FilterOverdue = True;
	FilterAll = False;
	
	EventDate = SelectionClickATServerIsOverdue();
	SetSelectionOverdue(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure HyperlinkForTodayClick(Item)
	
	SelectionForToday = True;
	FilterAll = False;
	
	FilterPeriod = New StandardPeriod(StandardPeriodVariant.Today);
	SetSelectionForToday(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	SetSelectionItem();
	
	FilterAll = False;
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure FilterStateOnChange(Item)
	
	SetSelectionState(ThisObject);
	
	FilterAll = False;
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	SetSelectionResponsible(ThisObject);
	
	FilterAll = False;
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure HyperlinkGoodsResearchClick(Item)
	OpenForm("Document.GoodsQualityResearch.Form.ResearchConductingForm");
	Return;
	
EndProcedure

&AtClient
Procedure HyperlinkQualityControlCertificatesClick(Item)
	
	OpenForm("Document.GoodsQualityControlCertificate.Form.ListForm");
	
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
	Template = NStr("vi = '%1 từ %2';
					|ru = '%1 из %2';
					|en = '%1 out of %2'; fa = '%1 out of %2';
					|it = '%1 da %2';
					|pl = '%1 z %2';
					|tr = '%2''dan %1'");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsQualityResearch.RequestForControl AS Ref,
	|	COUNT(GoodsQualityResearch.Ref) AS TotalCount1,
	|	SUM(CASE
	|		WHEN GoodsQualityResearch.Completed = TRUE
	|			THEN 1
	|		ELSE 0
	|	END) AS NumberOfCompleted
	|FROM
	|	Document.GoodsQualityResearch AS GoodsQualityResearch
	|WHERE
	|	GoodsQualityResearch.RequestForControl IN (&ControlRequests)
	|	AND GoodsQualityResearch.DeletionMark = FALSE
	|	AND GoodsQualityResearch.Posted = TRUE
	|GROUP BY
	|	GoodsQualityResearch.RequestForControl";
	
	Query.SetParameter("ControlRequests", Rows.GetKeys());
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		ListLine = Rows[Selection.Ref];
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(Template, Selection.NumberOfCompleted, Selection.TotalCount1);
		ListLine.Data["StudiesPerformed"] = Presentation;
	EndDo;
	Return;

EndProcedure

&AtClient
Procedure StudiesPerformedClick(Item, StandardProcessing)
	StandardProcessing = False;
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref", CurrentData.Ref);
	OpenForm("Document.GoodsQualityResearch.Form.ResearchStateForm", FormParameters, ThisObject);
	Return;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	If Field = Items.StudiesPerformed Then
		FormParameters = New Structure;
		FormParameters.Insert("RequestForControl", CurrentData.Ref);
		OpenForm("Document.GoodsQualityResearch.Form.ResearchStateForm", FormParameters,
			ThisObject);
	Else
		FormParameters = New Structure;
		FormParameters.Insert("Key", CurrentData.Ref);
		OpenForm("Document.RequestForGoodsQualityControl.Form.DocumentForm", FormParameters,
			ThisObject);
	EndIf;
	Return;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AssignResearch(Command)
	ClearMessages();
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn dòng nào, lệnh không thể thực hiện.';
								|ru = 'Не выбраны строки, команда не может быть выполнена.';
								|en = 'No lines are selected, cannot run the command.'; fa = 'No lines are selected, cannot run the command.';
								|it = 'No lines are selected, cannot run the command.';
								|pl = 'No lines are selected, cannot run the command.';
								|tr = 'Satır seçilmedi, komut gerçekleştirilemez.'"));
		Return;
	EndIf;
	
	CheckResult = CheckReadinessForRegistrationOfStudies(CurrentData.Ref);
	If Not CheckResult.DocumentPosted Then
		ErrorText = NStr("vi = 'Không thể chỉ định nghiên cứu cho chứng từ chưa được kết chuyển.';
						|ru = 'Невозможно назначить исследование для непроведенного документа.';
						|en = 'Cannot assign research for an unposted document.'; fa = 'Cannot assign research for an unposted document.';
						|it = 'Cannot assign research for an unposted document.';
						|pl = 'Cannot assign research for an unposted document.';
						|tr = 'Kaydedilmemiş belge için inceleme atanamaz.'");
		CommonClient.MessageToUser(ErrorText, , , ,);
		Return;
	EndIf;
	
	If Not CheckResult.ThereAreUnconfirmedLines Then
		ErrorText = NStr("ru = 'Качество подтверждено, не требуется назначение исследований.';
						|vi = 'The quality is confirmed, no research is required.';
						|en = 'The quality is confirmed, no research is required.'; fa = 'The quality is confirmed, no research is required.';
						|it = 'The quality is confirmed, no research is required.';
						|pl = 'The quality is confirmed, no research is required.';
						|tr = 'Kalite onaylandı, inceleme ataması gerekmiyor.'");
		CommonClient.MessageToUser(ErrorText, , , ,);
		Return;
	EndIf;
	
	OpenResearchAssignment(CurrentData.Ref);
	Return;
	
EndProcedure

&AtClient
Procedure IssueControlReport(Command)
	ClearMessages();
	CurrentData = Items.List.CurrentData;

	If CurrentData = Undefined Then
		ShowMessageBox( , NStr("vi = 'Chưa chọn dòng nào, lệnh không thể thực hiện.';
								|ru = 'Не выбраны строки, команда не может быть выполнена.';
								|en = 'No lines are selected, cannot run the command.'; fa = 'No lines are selected, cannot run the command.';
								|it = 'No lines are selected, cannot run the command.';
								|pl = 'No lines are selected, cannot run the command.';
								|tr = 'Satır seçilmedi, komut gerçekleştirilemez.'"));
		Return;
	EndIf;

	ApplicationHasBeenCompleted = ApplicationHasBeenCompleted(CurrentData.Ref);
	If Not ApplicationHasBeenCompleted Then
		ErrorText = NStr("vi = 'Không thể lập chứng từ kiểm soát cho chứng từ chưa được kết chuyển.';
						|ru = 'Невозможно оформить акт контроля для непроведенного документа.';
						|en = 'Cannot issue a control certificate for an unposted document.'; fa = 'Cannot issue a control certificate for an unposted document.';
						|it = 'Cannot issue a control certificate for an unposted document.';
						|pl = 'Cannot issue a control certificate for an unposted document.';
						|tr = 'Kaydedilmemiş belge için kontrol tutanağı düzenlenemez.'");
		CommonClient.MessageToUser(ErrorText, , , , );
		Return;
	Else
		FormParameters = GetParametersOfQualityControlReportForm();

		If FormParameters <> Undefined Then
			OpenForm("Document.GoodsQualityControlCertificate.Form.DocumentForm", FormParameters);
		EndIf;
	EndIf;
	Return;
	
EndProcedure

#EndRegion

#Region Private
#Region QualityControlAct

&AtClient
Function GetParametersOfQualityControlReportForm()
	
	ListOfStudies = New Array;
	
	RowData = Items.List.RowData(Items.List.SelectedRows[0]);
	
	If RowData.State = PredefinedValue("Enum.StatesOfResearchRequests.PendingResearch") Then
		ShowMessageBox(, NStr("vi = 'Chưa chỉ định nghiên cứu, lệnh không thể thực hiện.';
								|ru = 'Исследования не назначены, команда не может быть выполнена.';
								|en = 'The research is not assigned. Cannot run the command.'; fa = 'The research is not assigned. Cannot run the command.';
								|it = 'The research is not assigned. Cannot run the command.';
								|pl = 'The research is not assigned. Cannot run the command.';
								|tr = 'İncelemeler atanmamış, komut gerçekleştirilemez.'"));
		Return Undefined;
	EndIf;
	
	If RowData.State = PredefinedValue("Enum.StatesOfResearchRequests.InResearchProcess") Then
		ShowMessageBox(, NStr("vi = 'Chưa hoàn thành tất cả các nghiên cứu, lệnh không thể thực hiện.';
								|ru = 'Не все исследования завершены, команда не может быть выполнена.';
								|en = 'Not all the research is done. Cannot run the command.'; fa = 'Not all the research is done. Cannot run the command.';
								|it = 'Not all the research is done. Cannot run the command.';
								|pl = 'Not all the research is done. Cannot run the command.';
								|tr = 'Tüm incelemeler tamamlanmamış, komut gerçekleştirilemez.'"));
		Return Undefined;
	EndIf;
	
	ListOfStudies = ListOfStudiesWithCompletedQualityControlCertificates(RowData.Ref);
	If ListOfStudies.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không có nghiên cứu nào để lập chứng từ kiểm soát, lệnh không thể thực hiện.';
								|ru = 'Нет исследований для оформления акта контроля, команда не может быть выполнена.';
								|en = 'There is no research to register the control certificate. Cannot run the command.'; fa = 'There is no research to register the control certificate. Cannot run the command.';
								|it = 'There is no research to register the control certificate. Cannot run the command.';
								|pl = 'There is no research to register the control certificate. Cannot run the command.';
								|tr = 'Kontrol tutanağı düzenlemek için inceleme yok, komut gerçekleştirilemez.'"));
		Return Undefined;
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", RowData.Ref);
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

&AtServer
Procedure SetSelectionItem()
	
	If ValueIsFilled(FilterProducts) Then
	
		FilterList = New ValueList;
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	T.Ref AS Ref
		|FROM
		|	Document.RequestForGoodsQualityControl.Goods AS T
		|WHERE
		|	T.Products = &Products
		|";
		Query.SetParameter("Products", FilterProducts);
		
		FilterList.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
		
	EndIf;
		
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Mặt hàng';
			|ru = 'Номенклатура';
			|en = 'Item'; fa = 'قلم';
			|it = 'Item';
			|pl = 'Item';
			|tr = 'Öğe'"),
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
Procedure SetSelectionState(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"State",
		Form.FilterState,
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterState));
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishSelectionOnResearch(Form)
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"State",
		PredefinedValue("Enum.StatesOfResearchRequests.InResearchProcess"),
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.FilterOnResearch));
	Return;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionNoResearchAssigned(Form)
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"State",
		PredefinedValue("Enum.StatesOfResearchRequests.PendingResearch"),
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Form.SelectionOfStudyIsNotAssigned));
	Return;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionOverdue(Form)
	
	TypeOfEventDateComparison = DataCompositionComparisonType.LessOrEqual;
	
	FilterGroup = CommonClientServer.CreateFilterItemGroup(
		Form.List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Sự kiện';
			|ru = 'Событие';
			|en = 'Event'; fa = 'رویداد';
			|it = 'Event';
			|pl = 'Event';
			|tr = 'Olay'"), 
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		FilterGroup,
		"DueDate_2",
		TypeOfEventDateComparison,
		Form.EventDate,,
		ValueIsFilled(Form.EventDate));
		
	CommonClientServer.AddCompositionItem(
		FilterGroup,
		"DueDate_2",
		DataCompositionComparisonType.NotEqual,
		Date(1,1,1),,
		ValueIsFilled(Form.EventDate));
	CommonClientServer.AddCompositionItem(
		FilterGroup,
		"State",
		DataCompositionComparisonType.NotEqual,
		PredefinedValue("Enum.StatesOfResearchRequests.Completed_"),,
		ValueIsFilled(Form.EventDate));
EndProcedure

&AtServer
Function SelectionClickATServerIsOverdue()
	
	Return Common.CurrentUserDate();
	
EndFunction

&AtClientAtServerNoContext
Procedure SetSelectionForToday(Form)
	
	If ValueIsFilled(Form.FilterPeriod.StartDate) Then
		
		Items_Group = CommonClientServer.CreateFilterItemGroup(
			Form.List.Filter.Items,
			"GroupBegin",
			DataCompositionFilterItemsGroupType.OrGroup);
		
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"Date", 
			DataCompositionComparisonType.GreaterOrEqual, 
			Form.FilterPeriod.StartDate);
			
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"Date", 
			DataCompositionComparisonType.NotFilled);
			
	Else
		
		CommonClientServer.DeleteFilterItems(
			Form.List.Filter,
			"Date");
		
	EndIf;
	
	If ValueIsFilled(Form.FilterPeriod.EndDate) Then
		
		Items_Group = CommonClientServer.CreateFilterItemGroup(
			Form.List.Filter.Items,
			"EndGroup",
			DataCompositionFilterItemsGroupType.OrGroup);
		
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"Date", 
			DataCompositionComparisonType.LessOrEqual, 
			Form.FilterPeriod.EndDate);
			
		CommonClientServer.AddCompositionItem(
			Items_Group,
			"Date", 
			DataCompositionComparisonType.NotFilled);
			
	Else
		
		CommonClientServer.DeleteFilterItems(
			Form.List.Filter,
			"Date");
			
	EndIf;
	
EndProcedure

&AtClient
Procedure Clear_Filter()
	
	FilterStructure1 = StructureOfSelectionOfApplicationsForSelection();
	
	For Each Item In FilterStructure1 Do
		CommonClientServer.DeleteDynamicListFilterGroupItems(List, Item.Key); 
	EndDo;

	FilterState					= Undefined;
	FilterProducts				= Undefined;
	FilterEmployeeResponsible				= Undefined;
	SelectionForToday 					= False;
	SelectionOfStudyIsNotAssigned	= False;
	FilterOverdue 				= False;
	FilterOnResearch 			= False;
	FilterAll 						= True;
	
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Function StructureOfSelectionOfApplicationsForSelection()
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("State");
	FilterStructure1.Insert("Ref");
	FilterStructure1.Insert("EmployeeResponsible");
	FilterStructure1.Insert("Date");
	FilterStructure1.Insert("GroupBegin");
	FilterStructure1.Insert("EndGroup");
	FilterStructure1.Insert("NoStudiesHaveBeenAssigned");
	FilterStructure1.Insert("Event");
	FilterStructure1.Insert("DueDate_2");
	FilterStructure1.Insert("OnResearch");
	FilterStructure1.Insert("Products");
	
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
	
	SetSelectionState(ThisObject);
	SetSelectionItem();
	SetSelectionResponsible(ThisObject);
	
	FilterPeriod = New StandardPeriod(StandardPeriodVariant.Today);
	EventDate = SelectionClickATServerIsOverdue();
	If SelectionForToday Then
		SetSelectionForToday(ThisObject);
	EndIf;
	If FilterOnResearch Then
		EstablishSelectionOnResearch(ThisObject);
	EndIf;
	If SelectionOfStudyIsNotAssigned Then
		SetSelectionNoResearchAssigned(ThisObject);
	EndIf;
	If FilterOverdue Then
		SetSelectionOverdue(ThisObject);
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "Filter");
	
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
	Result.Insert("FilterState");
	Result.Insert("FilterProducts");
	Result.Insert("FilterEmployeeResponsible");
	Result.Insert("FilterAll");
	Result.Insert("SelectionForToday");
	Result.Insert("FilterOnResearch");
	Result.Insert("SelectionOfStudyIsNotAssigned");
	Result.Insert("FilterOverdue");
	
	Return Result;
	
EndFunction

&AtServer
Function ObjectKeySettingsManager()
	
	Return "RequestsForQualityControlOfGoods";
	
EndFunction

&AtServer
Function SettingsManagerSettingsKey()
	
	Return "FormSettings";
	
EndFunction

#EndRegion

#Region Other
&AtClient
Procedure OpenResearchAssignment(Ref)
	
	GoodsList = New Array;
	FormParameters = New Structure;
	FormParameters.Insert("RequestForControl", Ref);
	FormParameters.Insert("AllRows", True);
	FormParameters.Insert("GoodsList", GoodsList);
	OpenForm("Document.GoodsQualityResearch.Form.GenerationWizard", FormParameters, ThisObject);

EndProcedure

&AtServer
Function ListOfStudiesWithCompletedQualityControlCertificates(RequestForControl)

	ListOfStudies = GoodsResearch.ListOfStudiesOnApplicationForControl(RequestForControl);

	ListOfStudiesWithCompletedCertificates = GoodsResearch.ListOfStudiesWithCompletedQualityControlCertificates(
		ListOfStudies, RequestForControl);
	
	Return CommonClientServer.ArraysDifference(ListOfStudies, ListOfStudiesWithCompletedCertificates);

EndFunction

&AtServer
Function DynamicListQueryText1()

	QueryText =
	"SELECT
	|	RequestForGoodsQualityControl.Ref AS Ref,
	|	RequestForGoodsQualityControl.Number AS Number,
	|	RequestForGoodsQualityControl.Date AS Date,
	|	CASE
	|		WHEN RequestForGoodsQualityControl.Posted
	|			THEN ISNULL(RequestStatesForQualityControl.State,
	|				VALUE(Enum.StatesOfResearchRequests.Completed_))
	|		ELSE VALUE(Enum.StatesOfResearchRequests.EmptyRef)
	|	END AS State,
	|	RequestForGoodsQualityControl.Warehouse AS Warehouse,
	|	RequestForGoodsQualityControl.ReasonForGoodsLock AS ReasonForGoodsLock,
	|	RequestForGoodsQualityControl.ToScheduleGoodsUnlock AS ToScheduleGoodsUnlock,
	|	RequestForGoodsQualityControl.QualityConfirmationDate AS DueDate_2,
	|	RequestForGoodsQualityControl.ControlledLotReference AS ControlledLotReference,
	|	RequestForGoodsQualityControl.EmployeeResponsible AS EmployeeResponsible,
	|	RequestForGoodsQualityControl.Author AS Author,
	|	RequestForGoodsQualityControl.Comment AS Comment,
	|	CAST("""" AS STRING(10)) AS StudiesPerformed
	|FROM
	|	Document.RequestForGoodsQualityControl AS RequestForGoodsQualityControl
	|		LEFT JOIN InformationRegister.RequestStatesForQualityControl AS RequestStatesForQualityControl
	|		ON RequestStatesForQualityControl.Request = RequestForGoodsQualityControl.Ref";

	Return QueryText;

EndFunction
&AtServer
Procedure SetDynamicListProperties()
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = DynamicListQueryText1();
	ListProperties.MainTable = "Document.RequestForGoodsQualityControl";
	ListProperties.DynamicDataRead = True;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	Return;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
	// highlighting the expired quality control application in color
	#Region OverdueStudies
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField("DueDate_2");
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DueDate_2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = CurrentSessionDate();
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.StatesOfResearchRequests.Completed_;
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
		SetStateOfHyperlink(Form, Items.HyperlinkForToday, Form.SelectionForToday);
		SetStateOfHyperlink(Form, Items.HyperlinkNoResearchAssigned, Form.SelectionOfStudyIsNotAssigned);
		SetStateOfHyperlink(Form, Items.HyperlinkOverdue, Form.FilterOverdue);
		
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
Function CheckReadinessForRegistrationOfStudies(RequestForControl)
	
	Result = New Structure("DocumentPosted, ThereAreUnconfirmedLines", False, False);
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	RequestForGoodsQualityControl.Posted AS DocumentPosted,
		|	CASE
		|		WHEN TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.RequestForGoodsQualityControl.Goods AS Goods
		|			WHERE
		|				Goods.Ref = &Ref
		|				AND Goods.QualityIsConfirmed = FALSE)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThereAreUnconfirmedLines
		|FROM
		|	Document.RequestForGoodsQualityControl AS RequestForGoodsQualityControl
		|WHERE
		|	RequestForGoodsQualityControl.Ref = &Ref";
	
	Query.SetParameter("Ref", RequestForControl);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		FillPropertyValues(Result, Selection);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function ApplicationHasBeenCompleted(RequestForControl)
	
	Return Common.ObjectAttributeValue(RequestForControl, "Posted");
	
EndFunction
#EndRegion

#EndRegion
