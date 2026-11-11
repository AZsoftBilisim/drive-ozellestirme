
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	QueryText = "
	|SELECT
	|	Document.Ref                                 AS Ref,
	|	Document.Date                                   AS Date,
	|	Document.Number                                  AS Number,
	|	Document.Department                          AS Department,
	|	Document.Stage                                   AS Stage,
	|	Document.Operation                               AS Operation,
	|	Document.OperationID                  AS OperationID,
	|	Document.Performer                            AS Performer,
	|	Document.Performer                            AS PerformerNw,
	|	Document.ProductionArea                                AS ProductionArea,
	|	Document.ProductionArea                                AS PlotIsNew,
	|	CASE
	|		WHEN Document.WorkCenter REFS Catalog.WorkCenterTypes
	|			THEN Document.WorkCenter
	|		ELSE
	|			Document.WorkCenter.WorkCenterType
	|	END                                                                          AS WorkCenterType,
	|	CASE
	|		WHEN Document.WorkCenter REFS Catalog.WorkCenterTypes
	|			THEN Document.WorkCenter
	|		ELSE
	|			Document.WorkCenter.WorkCenterType
	|	END                                                                          AS ViewOfTheNewWorkCenter,
	|	CASE
	|		WHEN Document.WorkCenter REFS Catalog.WorkCenters
	|			THEN Document.WorkCenter
	|		ELSE
	|			VALUE(Catalog.WorkCenters.EmptyRef)
	|	END                                                                          AS WorkCenter,
	|	CASE
	|		WHEN Document.WorkCenter REFS Catalog.WorkCenters
	|			THEN Document.WorkCenter
	|		ELSE
	|			VALUE(Catalog.WorkCenters.EmptyRef)
	|	END                                                                          AS WorkCenterNov,
	|
	|	&TextTotalQuantity                                                          AS TotalCount1,
	|	&TextQuantityToBeExecuted                                                    AS QuantityToPerform,
	|	&TextQuantityToBeExecuted                                                    AS Count,
	|	ISNULL(Document.Operation.Count, 1)                                      AS NumberOfPieces,
	|	ISNULL(Document.Operation.UnitOfMeasure, Document.UnitOfMeasure)        AS UnitOfMeasure,
	|
	|	Document.TimePerPiece                                                          AS TimePerPiece,
	|	Document.TimePerPieceUnitOfMeasure                                                     AS TimePerPieceUnitOfMeasure,
	|	Document.SetupTime                                                               AS SetupTime,
	|	Document.SetupTimeUnitOfMeasure                                                          AS SetupTimeUnitOfMeasure,
	|	Document.RunTime                                                       AS ExecutionTimeOfEverything,
	|	Document.ExecutionTimeUnitOfMeasure                                                  AS ExecutionTimeUnitOfMeasure
	|
	|FROM
	|	Document.ProductionOperation2_2  AS Document
	|WHERE
	|	Document.Ref = &Ref";
	
	TextTotalQuantity = "Document.Count
	|		- Document.CountCanceled";
	
	TextQuantityToBeExecuted = "Document.Count
	|		- Document.CountCanceled
	|		- Document.FollowUp
	|		- Document.QuantityUnderRevision
	|		- Document.DefectiveGoodsCount
	|		- Document.CountReal";
	
	QueryText = StrReplace(QueryText, "&TextTotalQuantity",       TextTotalQuantity);
	QueryText = StrReplace(QueryText, "&TextQuantityToBeExecuted", TextQuantityToBeExecuted);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Parameters.Ref);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	FillPropertyValues(ThisObject, Selection);
	
	FillInAttributesOfRC();
	
	RecalculateTimeOnChangingQuantity(ThisObject);
	
	FillInUnitPresentation(ThisObject);
	
	Title = StrTemplate(NStr("vi = 'Chia giao dịch %1';
							|ru = 'Деление операции %1';
							|en = 'Operation division %1'; fa = 'Operation division %1';
							|it = 'Divisione dell''operazione %1';
							|pl = 'Dzielenie operacji %1';
							|tr = '%1 işleminin bölünmesi'"), Selection.Number);
	
	Items.NumberOfNewItems.MaxValue = QuantityToPerform;
	Items.LeadTimeIsNew.MaxValue = RunTime;
	
	AdjustVisibilityOfPlotElements(Selection.Department);
	
	If Common.IsMobileClient() Then
		AdaptToMobileClient();
	EndIf; 
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not DataIsUnlocked Then
		UnlockData(Ref, FormOwner.UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Count = 0 Then
		ClearMessages();
		MessageText = NStr("vi = 'Không có số lượng hợp lệ để tách biệt trong giao dịch khác.';
							|ru = 'Нет количества, доступного для отделения в другую операцию.';
							|en = 'There is no quantity available to be separated into another operation.'; fa = 'There is no quantity available to be separated into another operation.';
							|it = 'Non vi è una quantità disponibile per essere separata in un''altra operazione.';
							|pl = 'Brak ilości, dostępnej do wyodrzębnienia do innej operacji.';
							|tr = 'Başka bir işleme ayrılabilecek miktar yoktur.'");
		CommonClient.MessageToUser(MessageText,,,,Cancel);
		UnlockData(Ref, FormOwner.UUID);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Split(Command)
	
	If NumberOfNewItems = 0 Then
		
		MessageText = NStr("vi = 'Nhập dữ liệu không chính xác';
							|ru = 'Введены некорректные данные';
							|en = 'Incorrect data entered'; fa = 'Incorrect data entered';
							|it = 'Dati inseriti non sono corretti';
							|pl = 'Zostały wprowadzone nieprawidłowe dane';
							|tr = 'Yanlış veri girildi'");
		CommonClient.MessageToUser(MessageText,,"NumberOfNewItems");
		Return;
		
	EndIf;
	
	If Count = 0 And QuantityToPerform = TotalCount1 Then
		
		MessageText = NStr("vi = 'Nhập dữ liệu không chính xác';
							|ru = 'Введены некорректные данные';
							|en = 'Incorrect data entered'; fa = 'Incorrect data entered';
							|it = 'Dati inseriti non sono corretti';
							|pl = 'Zostały wprowadzone nieprawidłowe dane';
							|tr = 'Yanlış veri girildi'");
		CommonClient.MessageToUser(MessageText,,"Count");
		Return;
		
	EndIf;
	
	SplitOnServer(FormOwner.UUID);
	
	NotifyChanged(Ref);
	
	OperationKey = ProductionManagementClientServer.ProductionOperationKey();
	FillPropertyValues(OperationKey, ThisObject);
	
	NotificationParameter1 = New Structure;
	NotificationParameter1.Insert("Department", Department);
	NotificationParameter1.Insert("OperationKey",  OperationKey);
	NotificationParameter1.Insert("Ref",        Ref);
	Notify("Write_ProductionOperation2_2", NotificationParameter1, UUID);
	
	Close();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PerformerNwStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("PerformerNwStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Organization,
		Department,
		PerformerNw,
		Date,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure PerformerNwAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Department, Ref);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformerNwTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Department, Ref);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ViewOfTheNewWorkCenterOnChange(Item)
	
	FillInAttributesOfRC();
	
EndProcedure

&AtClient
Procedure WorkCenterNovOnChange(Item)
	
	FillInAttributesOfRC();
	
EndProcedure

&AtClient
Procedure NumberOfNewItemsOnChange(Item)
	
	Count = QuantityToPerform - NumberOfNewItems;
	
	RecalculateTimeOnChangingQuantity(ThisObject);
	
	FillInUnitPresentation(ThisObject);
	
EndProcedure

&AtClient
Procedure LeadTimeIsNewOnChange(Item)
	
	If TimePerPiece <> 0 Or SetupTime <> 0 Then
	
		NumberOfNewItems = ProductionAccountingClientServer.CalculateAmountOfOperationFromTime(
			LeadTimeIsNew,
			TimePerPiece,
			SetupTime,
			NumberOfPieces,
			AttributesOfNewRC.WorkTimeFactor);
			
	Else
		
		NumberOfNewItems = Count * LeadTimeIsNew / ExecutionTimeOfEverything;
		
	EndIf;
		
	Count = TotalCount1 - NumberOfNewItems;
	
	RecalculateTimeOnChangingQuantity(ThisObject);
	
	FillInUnitPresentation(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AdjustVisibilityOfPlotElements(Department)
	
	If ValueIsFilled(Department) Then
		
		SelectionOfFunctionalOptions = New Structure("Department", Department); 
		SetFormFunctionalOptionParameters(SelectionOfFunctionalOptions);
		Items.DecorationPlot.Visible = GetFunctionalOption("UseProductionSites", SelectionOfFunctionalOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformerNwStartChoiceCompletion(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result) Then
		
		PerformerNw = Result;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInUnitPresentation(Form)

	Form.UnitOfMeasurePresentation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		Form.UnitOfMeasure,
		Form.Count);
		
	Form.UnitOfMeasurementNewRepresentation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		Form.UnitOfMeasure,
		Form.NumberOfNewItems);
	
EndProcedure

&AtServerNoContext
Procedure PerformerGettingSelectionData(ChoiceData, Text, Department, Ref)
	
	ChoiceData = New ValueList;
	FilterParameters = New Structure("Organization, Department, Date");
	FilterParameters.Department = Department;
	FilterParameters.Date = Common.ObjectAttributeValue(Ref, "Date");
	ProductionServer.FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, FilterParameters);
	
EndProcedure

&AtServer
Procedure SplitOnServer(FormIdentifier)
	
	FillingValues = Documents.ProductionOperation2_2.SplittingParametersOfOperationConstructor();
	FillingValues.Performer       = PerformerNw;
	FillingValues.ProductionArea           = PlotIsNew;
	FillingValues.WorkCenter      = ?(ValueIsFilled(WorkCenterNov), WorkCenterNov, ViewOfTheNewWorkCenter);
	FillingValues.Count        = NumberOfNewItems;
	FillingValues.RunTime   = LeadTimeIsNew;
	
	Try
		
		Documents.ProductionOperation2_2.Split(Ref, FillingValues, False);
		
	Except
		
		UnlockDataForEdit(Ref, FormIdentifier);
		DataIsUnlocked = True;
		
		Raise StrTemplate(
			NStr("vi = 'Không thể hoàn thành hành động vì: %1';
				|ru = 'Не удалось выполнить действие по причине: %1';
				|en = 'Cannot perform the action. Reason: %1'; fa = 'Cannot perform the action. Reason: %1';
				|it = 'Non è stato possibile eseguire azione a causa di: %1';
				|pl = 'Nie udało się wykonać czynności z powodu: %1';
				|tr = 'Eylemin gerçekleştirilememe nedeni: %1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		
	EndTry;
	
	UnlockDataForEdit(Ref, FormIdentifier);
	DataIsUnlocked = True;
	
EndProcedure

&AtServerNoContext
Procedure UnlockData(Ref, FormIdentifier)
	
	UnlockDataForEdit(Ref, FormIdentifier);
	
EndProcedure

&AtServer
Procedure AdaptToMobileClient()
	
	Group = ChildFormItemsGroup.Vertical;
	
	Title = NStr("vi = 'Hoạt động mới';
				|ru = 'Новая операция';
				|en = 'New operation'; fa = 'عملیات جدید';
				|it = 'Nuova operazione';
				|pl = 'Nowa operacja';
				|tr = 'Yeni işlem'");
	
	CommandBarLocation = FormCommandBarLabelLocation.Top;
	
	Items.FormSplit.Representation = ButtonRepresentation.Picture;
	Items.FormSplit.Picture    = PictureLib.WriteAndClose;
	
	Items.Group4.ShowTitle = False;
	
	Items.Group2.Visible = False;
	Items.Group5.Visible = False;
	
	Items.PerformerNw.TitleLocation       = FormItemTitleLocation.Left;
	Items.PlotIsNew.TitleLocation           = FormItemTitleLocation.Left;
	Items.ViewOfTheNewWorkCenter.TitleLocation = FormItemTitleLocation.Left;
	Items.WorkCenterNov.TitleLocation      = FormItemTitleLocation.Left;
	Items.NumberOfNewItems.TitleLocation        = FormItemTitleLocation.Left;
	Items.LeadTimeIsNew.TitleLocation   = FormItemTitleLocation.Left;
	
	Items.LeadTimeIsNew.Width = 0;
	Items.LeadTimeIsNew.HorizontalAlign = ItemHorizontalLocation.Right;
	Items.ExecutionTimeUnitOfMeasure1.Width = 0;
	Items.ExecutionTimeUnitOfMeasure1.AutoMaxWidth = False;
	Items.ExecutionTimeUnitOfMeasure1.MaxWidth = 7;
	Items.ExecutionTimeUnitOfMeasure1.HorizontalAlign = ItemHorizontalLocation.Left;
	
	Items.NumberOfNewItems.Width = 0;
	Items.NumberOfNewItems.HorizontalAlign = ItemHorizontalLocation.Right;
	Items.UnitOfMeasurementNewRepresentation.Width = 0;
	Items.UnitOfMeasurementNewRepresentation.AutoMaxWidth = False;
	Items.UnitOfMeasurementNewRepresentation.MaxWidth = 7;
	Items.UnitOfMeasurementNewRepresentation.HorizontalAlign = ItemHorizontalLocation.Left;
	
	Items.ViewOfTheNewWorkCenter.Title = NStr("vi = 'Dạng nguồn lực sản xuất';
												|ru = 'Вид РЦ';
												|en = 'Work center type'; fa = 'نوع مرکز کاری';
												|it = 'Tipo dei centri di lavoro';
												|pl = 'Rodzaj CP';
												|tr = 'İM türü'");
	Items.WorkCenterNov.Title      = NStr("vi = 'Nguồn lực sản xuất';
											|ru = 'Рабочий центр';
											|en = 'Work center'; fa = 'مرکز کاری';
											|it = 'Centro di lavoro';
											|pl = 'Centrum pracy';
											|tr = 'İş merkezi'");
	Items.PlotIsNew.Title           = NStr("vi = 'Khu vực';
											|ru = 'Участок';
											|en = 'Area'; fa = 'مساحت';
											|it = 'Sito';
											|pl = 'Działka';
											|tr = 'Saha'");
	
	If Not QuantityToPerform = TotalCount1 Then
		
		NumberOfNewItems      = Count;
		Count         = 0;
		LeadTimeIsNew = RunTime;
		RunTime    = 0;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateTimeOnChangingQuantity(Form)
	
	If Form.TimePerPiece <> 0 Or Form.SetupTime <> 0 Then
		
		If Form.Count = Form.TotalCount1 Then
			
			Form.RunTime = Form.ExecutionTimeOfEverything;
			
		Else
		
			Form.RunTime = ProductionAccountingClientServer.CalculateOperationTimeFromQuantity(
					Form.Count,
					Form.NumberOfPieces,
					Form.TimePerPiece,
					Form.SetupTime,
					Form.RCDetails.ParallelLoad,
					Form.RCDetails.WorkTimeFactor);
				
		EndIf;
		
		Form.LeadTimeIsNew = ProductionAccountingClientServer.CalculateOperationTimeFromQuantity(
				Form.NumberOfNewItems,
				Form.NumberOfPieces,
				Form.TimePerPiece,
				Form.SetupTime,
				Form.AttributesOfNewRC.ParallelLoad,
				Form.AttributesOfNewRC.WorkTimeFactor);
		
	Else
		
		Form.RunTime = Form.ExecutionTimeOfEverything * Form.Count / Form.TotalCount1;
		
		Form.LeadTimeIsNew = Form.ExecutionTimeOfEverything * Form.NumberOfNewItems / Form.TotalCount1;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAttributesOfRC()
	
	RCDetails = ProductionAccounting.AttributesOfWorkCenter(
		?(ValueIsFilled(WorkCenter), WorkCenter, WorkCenterType));
		
	AttributesOfNewRC = ProductionAccounting.AttributesOfWorkCenter(
		?(ValueIsFilled(WorkCenterNov), WorkCenterNov, ViewOfTheNewWorkCenter));
	
EndProcedure

#EndRegion
