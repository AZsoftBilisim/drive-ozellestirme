#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details
&AtClient
Var RepeatCallBeforeRecording; // Used for non-modal questions before recording

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	BalanceViewIsAvailable = SelfServiceServer.YouCanViewBalancesInSelection();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If PrintFormOpeningIsRequired Then
		Cancel = True;
		Return;
	EndIf;
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Object.Ref.IsEmpty() Then
		
		SelfServiceServer.SelfServiceFormsWhenCreatedOnServer(ThisForm, Cancel);
		If Cancel Then
			Return;
		EndIf;
		
		Title = NStr("vi = 'Kế hoạch mua hàng (tạo mới)';
					|ru = 'План закупок (создание)';
					|en = 'Purchase plan (create)'; fa = 'Purchase plan (create)';
					|it = 'План закупок (создание)';
					|pl = 'Purchase plan (create)';
					|tr = 'Satın alma planı (kurum)'");
		Object.CrossTable = True;
		OnReadCreateAtServer();
		
	EndIf;
	
	Planning.SaveNewPeriod(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.FormGroupStandard);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	If CurrentObject.Status <> Enums.PlanStatuses.UnderPreparation Then
		PrintFormOpeningIsRequired = True;
		Return;
	EndIf;
	
	CurrentObject.CrossTable = True;
	SetHeader();
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues);
		
	EndIf;
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.Terms.IsEmpty() Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra thỏa thuận';
												|ru = 'Не указано соглашение';
												|en = 'Agreement is not specified'; fa = 'Agreement is not specified';
												|it = 'L''accordo non è specificato';
												|pl = 'Nie określono żadnej umowy';
												|tr = 'Anlaşma belirtilmedi'"),
		                                                  ,
		                                                  "Object.Terms",
		                                                  ,
		                                                  Cancel);
		Return;
	EndIf;
	
	If RepeatCallBeforeRecording = True Then
		RepeatCallBeforeRecording = False;
		Return;
	Else
		
		UpdateRelatedItemDetails(Object, ThisForm);
	
		ChangeTablePresentation(CachedValues, False);
		
	EndIf; 
	
	AdditionalParameters = New Structure;
	QueryText = "";
	Buttons = New ValueList;
	ThereIsQuestionToUser = False;
	
	AmountOfPaymentStages = Object.CashFlowPlan.Total("PaymentAmount");
	
	If Object.FillInPaymentPlan And Object.DocumentAmount = 0 And Object.CashFlowPlan.Count() > 0 Then
		
		NumberOfScheduledRows = Object.Goods.FindRows(New Structure("Canceled", False)).Count();
		
		ThereIsQuestionToUser = True;
		AdditionalParameters.Insert("ClearPaymentPlan", True);
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Đồng ý';
												|ru = 'ОК';
												|en = 'OK'; fa = 'تأیید';
												|it = 'OK';
												|pl = 'OK';
												|tr = 'Tamam'"));
		If Not Object.Posted Then
			Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Anuluj';
														|tr = 'İptal'"));
		EndIf; 
		If NumberOfScheduledRows = 0 And Object.CashFlowPlan.Count() > 0 Then
			
			QueryText = ?(Object.Posted,
			NStr("vi = 'Đã hủy tất cả các dòng trong kế hoạch. Sẽ xóa bảng kế hoạch thanh toán';
				|ru = 'В плане все строки отменены. Таблица плана оплаты будет очищена';
				|en = 'All lines have been canceled. The Payment plan tab will be cleared.'; fa = 'All lines have been canceled. The Payment plan tab will be cleared.';
				|it = 'Tutte le righe del piano sono annullate. I dati nella tabella del piano dei pagamenti verranno eliminati';
				|pl = 'W planie wszystkie linie są anulowane. Tabela planu płatności zostanie wyczyszczona';
				|tr = 'Plandaki tüm satırlar iptal edildi. Ödeme planı tablosu temizlenecektir'"),
			NStr("vi = 'Đã hủy tất cả các dòng trong kế hoạch. Xóa bảng kế hoạch thanh toán?';
				|ru = 'В плане все строки отменены. Очистить таблицу плана оплаты?';
				|en = 'All plan lines are canceled. Clear the payment plan table?'; fa = 'All plan lines are canceled. Clear the payment plan table?';
				|it = 'Tutte le righe del piano sono annullate. Eliminare i dati nella tabella del piano dei pagamenti?';
				|pl = 'W planie wszystkie linie są anulowane. Wyczyść tabelę planu płatności?';
				|tr = 'Plandaki tüm satırlar iptal edildi. Ödeme planı tablosu temizlensin mi?'"));
			
		Else
			
			QueryText = ?(Object.Posted,
			NStr("vi = 'Số tiền tại các dòng kế hoạch bằng 0. Bảng kế hoạch thanh toán sẽ bị xóa.';
				|ru = 'Сумма запланированных строк нулевая. Таблица плана оплаты будет очищена';
				|en = 'The lines total is 0. The Payment plan tab will be cleared.'; fa = 'The lines total is 0. The Payment plan tab will be cleared.';
				|it = 'La somma delle righe programmate è pari a zero. I dati nella tabella dei pagamenti verranno eliminati';
				|pl = 'Wartość zaplanowanych wierszy wynosi zero. Tabela planu płatności zostanie wyczyszczona';
				|tr = 'Planlanan satırların tutarı sıfır. Ödeme planı tablosu temizlenecektir'"),
			NStr("vi = 'Số tiền của các dòng kế hoạch bằng 0. Xóa bảng kế hoạch thanh toán?';
				|ru = 'Сумма запланированных строк нулевая. Очистить таблицу плана оплаты?';
				|en = 'Sum of the planned lines equals to 0. Clear the payment plan table?'; fa = 'Sum of the planned lines equals to 0. Clear the payment plan table?';
				|it = 'La somma delle righe programmate è pari a zero. Eliminare i dati nella tabella del piano dei pagamenti?';
				|pl = 'Wartość zaplanowanych wierszy wynosi zero. Wyczyść tabelę planu płatności?';
				|tr = 'Planlanan satırların tutarı sıfır. Ödeme planı tablosu temizlensin mi?'"));
			
		EndIf;
		
	ElsIf Object.FillInPaymentPlan And Object.DocumentAmount <> AmountOfPaymentStages Then
		
		ThereIsQuestionToUser = True;
		
		AgreementScheduleIsFilledIn = PaymentStepsServerCall.AgreementScheduleIsFilledIn(Object.Terms);
		ScheduleIsFull = (UsePaymentSchedules And ValueIsFilled(Object.PaymentSchedule))
			Or Object.PaymentScheduleSteps.Count() > 0;
		
		If Object.CashFlowPlan.Count() = 0 Then
			
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
													|ru = 'Заполнить';
													|en = 'Fill'; fa = 'پرکردن';
													|it = 'Compilare';
													|pl = 'Fill';
													|tr = 'Doldur'"));
			Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Chưa điền';
														|ru = 'Не заполнять';
														|en = 'Do not fill in'; fa = 'پر نشود';
														|it = 'Non compilare';
														|pl = 'Nie wypełniaj';
														|tr = 'Doldurma'"));
			
			If AgreementScheduleIsFilledIn Then
				QueryText = NStr("vi = 'Không có các giai đoạn trong kế hoạch thanh toán. 
					|Điền các giai đoạn tương ứng với thỏa thuận?';
					|ru = 'Отсутствуют этапы плана оплаты. 
					|Заполнить этапы в соответствии с соглашением?';
					|en = 'No payment plan steps.
					|Fill in the steps according to the agreement?'; fa = 'No payment plan steps.
					|Fill in the steps according to the agreement?';
					|it = 'Mancano le fasi del piano di pagamento. 
					|Compilare le fasi secondo l''accordo?';
					|pl = 'Nie ma żadnych kroków w planie płatności. 
					|Wypełniaj etapy zgodnie z umową?';
					|tr = 'Ödeme planının aşamaları eksik.
					|Aşamalar uygunluğa ve anlaşmaya göre doldurulsun mu?'");
			ElsIf ScheduleIsFull Then
				QueryText = NStr("vi = 'Không có các giai đoạn trong kế hoạch thanh toán. 
					|Điền các giai đoạn tương ứng với lịch biểu?';
					|ru = 'Отсутствуют этапы плана оплаты. 
					|Заполнить этапы в соответствии с графиком?';
					|en = 'No payment plan steps.
					|Fill in the steps according to the schedule?'; fa = 'No payment plan steps.
					|Fill in the steps according to the schedule?';
					|it = 'Mancano le fasi del piano di pagamento. 
					|Compilare le fasi secondo lo scadenzario?';
					|pl = 'Nie ma żadnych kroków w planie płatności. 
					|Wypełnij etapy zgodnie z harmonogramem?';
					|tr = 'Ödeme planlarının aşamaları eksik.
					|Aşamalar uygunluğa ve programa göre doldurulsun mu?'");
			Else
				QueryText = NStr("vi = 'Không có các giai đoạn trong kế hoạch thanh toán. 
					|Điền các giai đoạn, sau khi thêm một giai đoạn ""%PaymentOption%"" vào kỳ có thanh toán 100%?';
					|ru = 'Отсутствуют этапы плана оплаты. 
					|Заполнить этапы, добавив один этап ""%PaymentOption%"" на период с оплатой 100%?';
					|en = 'You didn''t specify any payment milestone.
					|We can add a milestone %PaymentOption%, 100%. Add the milestone?'; fa = 'You didn''t specify any payment milestone.
					|We can add a milestone %PaymentOption%, 100%. Add the milestone?';
					|it = 'Mancano le fasi del piano di pagamento. 
					|Compilare le fasi aggiungendo una fase ""%PaymentOption%"" per il periodo con il pagamento 100%?';
					|pl = 'Nie ma żadnych kroków w planie płatności. 
					|Wypełnij kroki, dodając jeden krok ""%PaymentOption%"" przez okres ze 100% płatnością?';
					|tr = 'Ödeme planlarının aşamaları eksik. 
					|Aşamalar bir ""%PaymentOption%"" eklenerek döneme göre %100 ödemeli olacak şekilde doldurulsun mu?'");
				QueryText = StrReplace(QueryText, "%PaymentOption%", 
					PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment"));
			EndIf;
			
		Else
			
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Điền lại';
													|ru = 'Перезаполнить';
													|en = 'Refill'; fa = 'پرکردن مجدد';
													|it = 'Ricompilare';
													|pl = 'Refill';
													|tr = 'Yeniden doldur'"));
			Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Chưa điền';
														|ru = 'Не заполнять';
														|en = 'Do not fill in'; fa = 'پر نشود';
														|it = 'Non compilare';
														|pl = 'Nie wypełniaj';
														|tr = 'Doldurma'"));
			
			If AgreementScheduleIsFilledIn Then
				QueryText = NStr("vi = 'Số tiền các giai đoạn thanh toán không trùng với số tiền trong các dòng lập kế hoạch. 
					|Điền lại các giai đoạn theo thỏa thuận?';
					|ru = 'Сумма этапов плана оплаты не совпадает с суммой запланированных строк. 
					|Перезаполнить этапы в соответствии с соглашением?';
					|en = 'Sum of the payment plan steps does not match the sum of planned lines.
					|Refill the steps in accordance with the agreement?'; fa = 'Sum of the payment plan steps does not match the sum of planned lines.
					|Refill the steps in accordance with the agreement?';
					|it = 'La somma delle fasi del piano di pagamento non coincide con la somma delle righe pianificate. 
					| Ricompilare le fasi secondo l''accordo?';
					|pl = 'Suma etapów planu płatności nie pokrywa się z sumą planowanych wierszy. 
					|Ponownie etapy zgodnie z umową?';
					|tr = 'Ödeme planı aşaması tutarı ile programlanan satır tutarı uyuşmuyor. 
					| Aşamalar anlaşma ile uygunluğa göre yeniden doldurulsun mu?'");
			ElsIf ScheduleIsFull Then
				QueryText = NStr("vi = 'Số tiền các giai đoạn thanh toán không trùng với số tiền trong các dòng lập kế hoạch.
					|Điền lại các giai đoạn theo lịch biểu?';
					|ru = 'Сумма этапов плана оплаты не совпадает с суммой запланированных строк. 
					|Перезаполнить этапы в соответствии с графиком?';
					|en = 'Sum of the payment plan steps does not match the sum of planned lines.
					|Refill the steps in accordance with the schedule?'; fa = 'Sum of the payment plan steps does not match the sum of planned lines.
					|Refill the steps in accordance with the schedule?';
					|it = 'La somma delle fasi del piano di pagamento non coincide con la somma delle righe pianificate. 
					| Ricompilare le fasi secondo lo scadenzario?';
					|pl = 'Wartość etapów planu płatności nie pokrywa się z sumą planowanych wierszy. 
					|Uzupełnij etapy zgodnie z harmonogramem?';
					|tr = 'Ödeme planı aşaması tutarı ile programlanan satır tutarı uyuşmuyor. 
					|Aşamalar grafik ile uygunluğa göre yeniden doldurulsun mu?'");
			Else
				QueryText = NStr("vi = 'Số tiền các giai đoạn thanh toán không trùng với số tiền trong các dòng lập kế hoạch. 
					|Điền lại các giai đoạn, sau khi bổ sung một giai đoạn ""%PaymentOption%"" trong kỳ với thanh toán 100%?';
					|ru = 'Сумма этапов плана оплаты не совпадает с суммой запланированных строк. 
					|Перезаполнить этапы, добавив один этап ""%PaymentOption%"" на период с оплатой 100%?';
					|en = 'Sum of the payment plan steps does not match the sum of planned lines.
					|Refill the steps by adding the ""%PaymentOption%"" step for the period with 100% payment?'; fa = 'Sum of the payment plan steps does not match the sum of planned lines.
					|Refill the steps by adding the ""%PaymentOption%"" step for the period with 100% payment?';
					|it = 'La somma delle fasi del piano di pagamento non coincide con la somma delle righe pianificate. 
					| Ricompilare le fasi aggiungendo una fase ""%PaymentOption%"" per il periodo con il pagamento 100%?';
					|pl = 'Wartość etapów planu płatności nie pokrywa się z sumą planowanych wierszy. 
					|Uzupełnij etapy, dodawszy etap ""%PaymentOption%"" na okres z płatnością 100%?';
					|tr = 'Ödeme planı aşaması ile programlanan satır tutarı uyuşmuyor. 
					|Etaplar 100% ödeme ile döneme yeni bir etap ""%PaymentOption%"" ekleyip yeniden doldurulsun mu?'");
				QueryText = StrReplace(QueryText, "%PaymentOption%", 
					PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment"));
			EndIf;
			
		EndIf;
		
		AdditionalParameters.Insert("ReFillStages", True);
		AdditionalParameters.Insert("AgreementScheduleIsFilledIn", AgreementScheduleIsFilledIn);
		AdditionalParameters.Insert("ScheduleIsFull", ScheduleIsFull);
		
	EndIf;
	
	If ThereIsQuestionToUser Then
		
		Notification = New CallbackDescription(
			"BeforeWriteCompletion",
			ThisObject,
			AdditionalParameters);
			
		ShowQueryBox(Notification, QueryText, Buttons);
		
		RepeatCallBeforeRecording = True;
		Cancel = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsForProductInCollection();
	SetHeader();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("TablePresentation",NStr("vi = 'Hàng hóa';
														|ru = 'Товары';
														|en = 'Goods'; fa = 'کالاها';
														|it = 'Merci';
														|pl = 'Goods';
														|tr = 'Ürünler'"));
	StructureOfActions.Insert("TablePath","GoodsByPeriod");
	
	StructureOfActions.Insert("GroupFields", "Products, Characteristic, Package, Warehouse, Partner, Terms");
	
	Planning.ProcessingFormFillVerification(GoodsByPeriod, 
		StructureOfActions, 
		Cancel, 
		CheckedAttributes, 
		Object.CrossTable);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ProcessChangesToPeriodInHeader();
	
EndProcedure

&AtClient
Procedure PeriodEndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ProcessChangesToPeriodInHeader();
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	UpdateRelatedItemDetails(Object, ThisForm);
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure("Partner,Terms, ThePlanningDetailsAreSpecified",Object.Partner,Object.Terms, True);
	
	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.SelectTermsOfSales",
		FormParameters,
		ThisForm,,,, 
		New CallbackDescription("TermsStartChoiceCompletion", ThisObject), 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TermsStartChoiceCompletion(SelectionResult, AdditionalParameters) Export
	
	If SelectionResult <> Undefined And SelectionResult.Terms <> Object.Terms Then
		If Not Object.Periodicity = PredefinedValue("Enum.Periodicity.EmptyRef") 
			And SelectionResult.Periodicity <> Object.Periodicity Then
			QueryText = NStr("vi = 'Đối với thỏa thuận đã chọn có đặt định kỳ lập kế hoạch khác. Dữ liệu về số lượng sẽ bị xóa. Tiếp tục?';
							|ru = 'Для выбираемого соглашения установлена другая периодичность планирования. Данные по количеству будут очищены. Продолжить?';
							|en = 'Other planning frequency is set for the selected agreement. Data on quantity will be cleared. Continue?'; fa = 'Other planning frequency is set for the selected agreement. Data on quantity will be cleared. Continue?';
							|it = 'Per l''accordo che viene selezionato è impostata un''altra periodicità di pianificazione. I dati relativi alla quantità verranno eliminati. Continuare?';
							|pl = 'W przypadku wybranej umowy ustala się inną częstotliwość planowania. Dane ilościowe zostaną wyczyszczone. Kontynuować?';
							|tr = 'Seçilen anlaşma için başka planlama sıklığı kuruldu. Miktara göre veriler temizlenecektir. Devam edilsin mi?'");
			
			ShowQueryBox(
			New CallbackDescription("AgreementIsBeginningOfChoosingAnswerToQuestion", ThisObject, New Structure("SelectionResult", SelectionResult)), 
				QueryText, 
				QuestionDialogMode.YesNo);
			Return;
		EndIf;
		TermsOnChangeServer(SelectionResult);
	EndIf;
	
	AvailabilityControl(ThisForm);

EndProcedure

&AtClient
Procedure AgreementIsBeginningOfChoosingAnswerToQuestion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	TermsOnChangeServer(AdditionalParameters.SelectionResult);
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure WarehouseClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Return;
	
EndProcedure

&AtClient
Procedure TermsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsByPeriod

&AtClient
Procedure GoodsByPeriodOnChange(Item)
	
	Modified = True;
	CalculateTotals_(ThisForm);
	
	Object.FilledAutomatically = False;
	UpdateRelatedItemDetails(Object, ThisForm);
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsByPeriodOnActivateCell(Item)
	
	SelfServiceClient.PlanSalesOfGoodsByPeriodWhenActivatingCell(Item, ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsByPeriodBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	OpenProductSelectionForm_1();
	
EndProcedure

&AtClient
Procedure WhenChangingQuantity(Item)
	
	RowOfGoods = Items.GoodsByPeriod.CurrentData;
	
	WhenChangingAmountOfRowSum(Object, RowOfGoods, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsByPeriodPriceOnChange(Item)
	
	RowOfGoods = Items.GoodsByPeriod.CurrentData;
	For Each PeriodString_ In ThisForm.TimeIntervals Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf;
		RowOfGoods["Price_" + PeriodString_.ColumnName] = RowOfGoods["Price"];
	EndDo;
	
	WhenChangingAmountOfRowSum(Object, RowOfGoods, CachedValues)
	
EndProcedure

&AtClient
Procedure GoodsByPeriodPackageOnChange(Item)
	
	CurrentRow = Items.GoodsByPeriod.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisForm, True);
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "GoodsByPeriodProducts" 
		Or Field.Name = "GoodsByPeriodCharacteristic" Then
		
		OpenProductItemCard();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCashFlowPlan

&AtClient
Procedure CashFlowPlanOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculatePaymentPlanTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure CashFlowPlanAfterDeleteRow(Item)
	
	CalculatePaymentPlanTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure CashFlowPlanPaymentAmountOnChange(Item)
	
	PaymentStage = Items.CashFlowPlan.CurrentData;
	
	PaymentStage.DebtAmount = PaymentStage.AmountByShipments - PaymentStage.PaymentAmount - PaymentStage.AmountByPayments;
	PaymentStage.PaymentPercentage = ?(PaymentStage.AmountByShipments > 0, 100 * PaymentStage.PaymentAmount / PaymentStage.AmountByShipments, 0);
	
	RecalculatePaymentPlanAmountsByLine(PaymentStage);
	
EndProcedure

&AtClient
Procedure CashFlowPlanPaymentPercentageOnChange(Item)
	
	PaymentStage = Items.CashFlowPlan.CurrentData;
	
	PaymentStage.PaymentAmount = PaymentStage.AmountByShipments * PaymentStage.PaymentPercentage / 100;
	PaymentStage.DebtAmount = PaymentStage.AmountByShipments - PaymentStage.PaymentAmount - PaymentStage.AmountByPayments;
	
	RecalculatePaymentPlanAmountsByLine(PaymentStage);
	
EndProcedure

&AtClient
Procedure CashFlowPlanPaymentDateOnChange(Item)
	
	Object.CashFlowPlan.Sort("PaymentDate");
	If Object.CashFlowPlan.Count() > 0 Then
	
		RecalculatePaymentPlanAmountsByLine(Object.CashFlowPlan.Get(0));
	
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.SalesPlan.SelfServiceWorkplaceDocumentForm.Command.SelectGoods");
	
	OpenProductSelectionForm_1();
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription(
		"SetDateIntervalCompletion",
		ThisObject);
		
	TMCommonUseClient.EditPeriod(
		Object, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "PeriodEnding"),
		Notification);
	
EndProcedure

&AtClient
Procedure SendForConfirmation(Command)
	
	ClearMessages();
	
	Cancel = False;
	
	If Object.Terms.IsEmpty() Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra thỏa thuận';
												|ru = 'Не указано соглашение';
												|en = 'Agreement is not specified'; fa = 'Agreement is not specified';
												|it = 'L''accordo non è specificato';
												|pl = 'Nie określono żadnej umowy';
												|tr = 'Anlaşma belirtilmedi'"),
		                                                  ,
		                                                  "Object.Terms",
		                                                  ,
		                                                  Cancel);
		Return;
	EndIf;
	
	Object.Status = PredefinedValue("Enum.PlanStatuses.AwaitingConfirmation");
	UpdateRelatedItemDetails(Object, ThisForm);
	WriteToServer(CachedValues, Cancel);
	If Cancel Then
		Return;
	EndIf;
	Notify("Write_SalesPlan", , Object.Ref);
	Close();
	
EndProcedure

&AtClient
Procedure OpenGoodsProfile(Command)
	
	OpenProductItemCard();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure FillInPaymentScheduleSteps(Command)
	
	PaymentAmountByStage = Object.CashFlowPlan.Total("PaymentAmount");
	
	AgreementScheduleIsFilledIn = PaymentStepsServerCall.AgreementScheduleIsFilledIn(Object.Terms);
	ScheduleIsFull = (UsePaymentSchedules And ValueIsFilled(Object.PaymentSchedule))
		Or Object.PaymentScheduleSteps.Count() > 0;
	
	If Object.DocumentAmount = 0 Then
		
		If Object.CashFlowPlan.Count() = 0 Then
			
			ShowMessageBox(,NStr("vi = 'Số tiền tại các dòng kế hoạch bằng 0. Không cần điền kế hoạch thanh toán.';
								|ru = 'Сумма запланированных строк нулевая. Заполнение плана оплаты не требуется.';
								|en = 'Sum of the planned lines equals to 0. It is not required to fill in the payment plan.'; fa = 'Sum of the planned lines equals to 0. It is not required to fill in the payment plan.';
								|it = 'La somma delle righe programmate è pari a zero. La compilazione del piano di pagamento non è necessaria.';
								|pl = 'Wartość zaplanowanych wierszy wynosi zero. Wymagane jest wypełnienie planu płatności.';
								|tr = 'Planlanan satırların tutarı sıfır. Ödeme planını doldurmaya gerek yok.'"));
			Return;
			
		EndIf;
		
		Object.CashFlowPlan.Clear();
		ShowUserNotification(
			NStr("vi = 'Đã xóa các giai đoạn thanh toán';
				|ru = 'Этапы оплаты очищены';
				|en = 'Payment milestones are cleared'; fa = 'Payment milestones are cleared';
				|it = 'Fasi di pagamento sono eliminate';
				|pl = 'Kroki płatności wyczyszczone';
				|tr = 'Ödeme aşamaları temizlendi'"),
			,
			NStr("vi = 'Số tiền tại các dòng kế hoạch bằng 0. Đã xóa bảng các giai đoạn thanh toán';
				|ru = 'Сумма запланированных строк нулевая. Таблица этапов оплаты очищена';
				|en = 'Sum of planned lines equals to 0. Payment milestone table is cleared'; fa = 'Sum of planned lines equals to 0. Payment milestone table is cleared';
				|it = 'La somma delle righe programmate è pari a zero. I dati nella tabella dei pagamenti sono eliminati';
				|pl = 'Wartość zaplanowanych wierszy wynosi zero. Tabela kroków płatności została wyczyszczona';
				|tr = 'Planlanan satırların tutarı sıfır. Ödeme aşaması tablosu temizlendi'"),
			PictureLib.Information32);
		Return;
		
	EndIf;
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(DialogReturnCode.Yes, NStr("vi = 'Điền lại phần bảng';
													|ru = 'Перезаполнить таблицу';
													|en = 'Refill table'; fa = 'Refill table';
													|it = 'Ricompilare la tabella';
													|pl = 'Ponownie wypełni tabelę';
													|tr = 'Tabloyu yeniden doldur'"));
	AnswersOptions.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
	
	ThereIsQuestionToUser = True;
	QueryText = "";
	ReFillStages = False;
	
	If Object.DocumentAmount = PaymentAmountByStage Then
		
		QueryText = NStr("vi = 'Số tiền tại các dòng kế hoạch trùng với số tiền trong các giai đoạn thanh toán';
						|ru = 'Сумма запланированных строк совпадает с суммой этапов оплаты';
						|en = 'Sum of planned lines matches the payment milestone sum'; fa = 'Sum of planned lines matches the payment milestone sum';
						|it = 'La somma delle righe pianificate coincide con la somma delle fasi del pagamento';
						|pl = 'Wartość zaplanowanych wierszy pokrywa się z wartością etapów płatności';
						|tr = 'Planlanan satırların tutarı ile ödeme aşamasının tutarı uyuşuyor'") + Chars.LF +
							NStr("vi = 'Điền lại giai đoạn thanh toán %SourceOfFilling%?';
								|ru = 'Перезаполнить этапы оплаты %SourceOfFilling%?';
								|en = 'Refill steps of payment %SourceOfFilling%?'; fa = 'Refill steps of payment %SourceOfFilling%?';
								|it = 'Ricompilare le fasi del pagamento %SourceOfFilling%?';
								|pl = 'Wypełnić ponownie etapy płatności%SourceOfFilling%?';
								|tr = 'Ödeme aşamalarını doldur %SourceOfFilling%?'");
		
	ElsIf Object.CashFlowPlan.Count() > 0 Then
		
		QueryText = NStr("vi = 'Điền bảng các giai đoạn thanh toán';
						|ru = 'Таблица этапов оплаты заполнена';
						|en = 'Payment milestones table is filled in'; fa = 'Payment milestones table is filled in';
						|it = 'La tabella delle fasi di pagamento è compilata';
						|pl = 'Tabela etapów płatności jest wypełniona';
						|tr = 'Ödeme aşaması tablosu dolduruldu'")+ Chars.LF +
							NStr("vi = 'Điền lại giai đoạn thanh toán %SourceOfFilling%?';
								|ru = 'Перезаполнить этапы оплаты %SourceOfFilling%?';
								|en = 'Refill steps of payment %SourceOfFilling%?'; fa = 'Refill steps of payment %SourceOfFilling%?';
								|it = 'Ricompilare le fasi del pagamento %SourceOfFilling%?';
								|pl = 'Wypełnić ponownie etapy płatności%SourceOfFilling%?';
								|tr = 'Ödeme aşamalarını doldur %SourceOfFilling%?'");
		
	Else
		
		ReFillStages = True;
		ThereIsQuestionToUser = False;
		
	EndIf;
	
	If ThereIsQuestionToUser Then
		
		If ScheduleIsFull Then
			QueryText = StrReplace(QueryText, "%SourceOfFilling%", NStr("vi = 'theo lịch biểu';
																		|ru = 'по графику';
																		|en = 'on schedule'; fa = 'on schedule';
																		|it = 'secondo il grafico';
																		|pl = 'wg harmonogramu';
																		|tr = 'programa göre'"));
		ElsIf AgreementScheduleIsFilledIn Then
			QueryText = StrReplace(QueryText, "%SourceOfFilling%", NStr("vi = 'theo thỏa thuận';
																		|ru = 'по соглашению';
																		|en = 'by agreement'; fa = 'by agreement';
																		|it = 'secondo l''accordo';
																		|pl = 'według umowy';
																		|tr = 'anlaşmaya göre'"));
		Else
			QueryText = StrReplace(QueryText, "%SourceOfFilling%", NStr("vi = 'theo mặc định';
																		|ru = 'по умолчанию';
																		|en = 'default'; fa = 'پیش‌فرض';
																		|it = 'per default';
																		|pl = 'domyślnie';
																		|tr = 'varsayılan'"));
		EndIf;
		
		AdditionalParameters = New Structure(
			"ReFillStages, AgreementScheduleIsFilledIn, ScheduleIsFull", 
			ReFillStages,
			AgreementScheduleIsFilledIn,
			ScheduleIsFull);
		Notification = New CallbackDescription(
			"FillInPaymentScheduleStepsCompletion", 
			ThisObject,
			AdditionalParameters);
		
		ShowQueryBox(Notification,QueryText, AnswersOptions);
		
	ElsIf ReFillStages Then
		
		FillOutPaymentPlan(AgreementScheduleIsFilledIn, ScheduleIsFull);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "GoodsByPeriodCharacteristic",
																		     "GoodsByPeriod.ItemVariantsAreUsed");
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashFlowPlanPaymentAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashFlowPlan.PaymentAmountIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTaskCompletionFlag);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashFlowPlanPaymentAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashFlowPlan.LineNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = New DataCompositionField("LineNumberOfFullPayment");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LineNumberOfFullPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.PositiveTaskCompletionFlag);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashFlowPlanDebtAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashFlowPlan.DebtAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AllowableAmountPayable");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LimitDebtAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTaskCompletionFlag);
	
EndProcedure

#Region WhenChangingBankingDetailsOnServer

&AtServer
Procedure TermsOnChangeServer(SelectionResult)

	NeedToUpdatePeriods = SelectionResult.Periodicity <> Object.Periodicity;
	FillPropertyValues(Object, SelectionResult,,"Warehouse");
	FillPropertyValues(ThisForm, SelectionResult);
	Object.Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(SelectionResult.Currency);
	PlanProfileOnChangeServer();
	If NeedToUpdatePeriods Then
		WhenChangingPeriodsOnServer(True);
	EndIf;
	
	If Object.FillInPaymentPlan 
		And ValueIsFilled(Object.Terms) 
		And SelectionResult.ContractsAreUsed Then
		
		ObjectParameters = New Structure;
		ObjectParameters.Insert("Contract", Object.Contract);
		ObjectParameters.Insert("Counterparty", SelectionResult.Counterparty);
		ObjectParameters.Insert("Partner", Object.Partner);
		ObjectParameters.Insert("Terms", Object.Terms);
		ObjectParameters.Insert("Organization", SelectionResult.Organization);
		ObjectParameters.Insert("BusinessOperation", SelectionResult.BusinessOperation);
		ObjectParameters.Insert("Currency", Object.Currency);
		
		Object.Contract = SalesServer.GetDefaultContract(ObjectParameters, 
			ObjectParameters.BusinessOperation, 
			ObjectParameters.Currency);
		AgreementWhenModifiedOnServer();
	Else
		Object.Contract = Undefined;
		LimitDebtAmount = False;
		AllowableAmountPayable = 0;
	EndIf;
	
	AvailabilityManagementChangeOfAgreement(SelectionResult);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date",          Object.BeginOfPeriod);
	FillParameters.Insert("Currency",        Object.Currency);
	FillParameters.Insert("Terms",    Object.Terms);
	FillParameters.Insert("PopulationFields", "Price, VATRate");
	
	If VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT
		And Not PriceIncludesVAT Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculatePriceWithVAT");
	Else
		StructureOfActions = Undefined;
	EndIf;
	
	EnterprisePricesFillingServer.FillInPrices(
		GoodsByPeriod,
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
		
	CalculateTotals_(ThisForm, True);
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure PlanProfileOnChangeServer(UpdateRule = False)

	UpdateRule = UpdateRule Or Object.PlanProfile <> ViewOfThePlanBeforeTheChange;
	
	PlanViewParameters = GetPlanViewParameters(Object.PlanProfile);
	FillPropertyValues(ThisForm, PlanViewParameters);
		
	If UpdateRule Then
		FillPropertyValues(Object, PlanViewParameters);
		Object.FilledAutomatically = False;
		If Not Object.PlanByAmount Then
			Object.FillInPaymentPlan = False;
		EndIf;
	EndIf;
	
	Planning.SaveNewPeriod(ThisForm);
	
	If ValueIsFilled(Object.PlanProfile) Then
		UpdateRelatedItemDetails(Object, ThisForm);
	EndIf;
	
EndProcedure

// The procedure fills the period table with dates to get the order and forms the fields of the cross-table.
&AtServer
Procedure WhenChangingPeriodsOnServer(AdjustStartEndOfPeriod = False)
	
	If AdjustStartEndOfPeriod Then
		PlanningClientServer.SetStartEndOfPlanPeriod(Object.Periodicity, 
			Object.BeginOfPeriod, 
			Object.PeriodEnding,
			CurrentSessionDate());
	EndIf; 
	
	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	
	Planning.FillInPeriodTable(TablePeriods, 
		Object.Periodicity, 
		Object.BeginOfPeriod, 
		Object.PeriodEnding);
	NumberOfPeriods = TablePeriods.FindRows(New Structure("Active_", True)).Count();
	
	Items.GoodsByPeriodNumberOfPackages.Visible = NumberOfPeriods > 1;
	
	Items.GoodsByPeriodPrice.Visible = Object.PlanByAmount;
	Items.GoodsByPeriodSum.Visible = Object.PlanByAmount;
	Items.Totals1Group.Visible = Object.PlanByAmount;
	
	OutputParameters = New Structure;
	OutputParameters.Insert("NameOfCrossTableProps", "GoodsByPeriod");
	OutputParameters.Insert("CrossTableFormElement", "GoodsByPeriod");
	OutputParameters.Insert("PeriodsTable", TablePeriods);
	OutputParameters.Insert("Periodicity", Object.Periodicity);
	
	OutputParameters.Insert("GroupFields_", True);
	OutputParameters.Insert("HeaderOfDimensionField", NStr("vi = 'Số lượng theo kỳ lập kế hoạch';
															|ru = 'Количество по периодам планирования';
															|en = 'Quantity by planning periods'; fa = 'Quantity by planning periods';
															|it = 'Quantità per periodi di pianificazione';
															|pl = 'Ilość według okresu planowania';
															|tr = 'Planlama dönemine göre miktar'"));
	
	OutputParameters.Insert("Fields", New Array());
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "Price_");
	FieldStructure.Insert("DeleteTableDetails", False);
	FieldStructure.Insert("CreateElement_", False);
	FieldStructure.Insert("ElementType", TMCommonUse.MoneyFieldTypeDescription());
	FieldStructure.Insert("Title", "Price");
	FieldStructure.Insert("CreateSummaryDetails", False);
	FieldStructure.Insert("ItemWidth", 6);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "WhenPriceChanges");
	FieldStructure.Insert("StructureOfActions", StructureOfActions);
	
	OutputParameters.Fields.Add(FieldStructure);
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "Sum_");
	FieldStructure.Insert("DeleteTableDetails", False);
	FieldStructure.Insert("CreateElement_", False);
	FieldStructure.Insert("ElementType", TMCommonUse.MoneyFieldTypeDescription());
	FieldStructure.Insert("Title", "Sum");
	FieldStructure.Insert("CreateSummaryDetails", True);
	FieldStructure.Insert("ItemWidth", 6);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "WhenChangingAmount_");
	FieldStructure.Insert("StructureOfActions", StructureOfActions);
	
	OutputParameters.Fields.Add(FieldStructure);	
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "Count_");
	FieldStructure.Insert("DeleteTableDetails", False);
	FieldStructure.Insert("CreateElement_", True);
	FieldStructure.Insert("ElementType", "Number");
	If NumberOfPeriods = 1 Then
		FieldStructure.Insert("Title", "Count");
	EndIf;
	FieldStructure.Insert("CreateSummaryDetails", True);
	FieldStructure.Insert("ItemWidth", 6);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("OnChange", "WhenChangingQuantity");
	FieldStructure.Insert("StructureOfActions", StructureOfActions);
	
	OutputParameters.Fields.Add(FieldStructure);
	
	Planning.UpdateCrosstabOutputStructure(ThisForm, OutputParameters);
	
	ValueToFormAttribute(TablePeriods,"TimeIntervals");
	
	Planning.SaveNewPeriod(ThisForm);
	
	CalculateTotals_(ThisForm, True);
	
EndProcedure

#EndRegion

#Region ManagingAvailabilityOfFormDetails

&AtServer
Procedure AvailabilityManagementChangeOfAgreement(Data)
	
	If Data = Undefined Then
		
		Items.Warehouse.Enabled = False;
		
	Else
		
		If FillInWarehouse Then
			SelfServiceServer.ManagingWarehouseFormElement(Object, Data, Items.Warehouse);
		Else
			Items.Warehouse.Enabled = False;
		EndIf;
		
	EndIf;
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	AvailabilityOfProducts = ValueIsFilled(Form.Object.Terms) 
	                   And ValueIsFilled(Form.Object.BeginOfPeriod)
	                   And ValueIsFilled(Form.Object.PeriodEnding);
	
	Form.Items.ProductsGroupCrossTable.Enabled = AvailabilityOfProducts;
	Form.Items.PaymentGroup_2.Enabled = AvailabilityOfProducts;
	Form.Items.GoodsByPeriodOpenGoodsProfile.Enabled = Form.GoodsByPeriod.Count() > 0;
	
EndProcedure

#EndRegion

#Region GeneratingAndDisplayingInformationOnForm

&AtClient
Procedure SetDateIntervalCompletion(Period, AdditionalParameters) Export 
	
	ProcessChangesToPeriodInHeader();
	
EndProcedure

&AtServer
Procedure SetHeader()
	
	Title = TitleText(Object.Number, Object.Date); 
	
EndProcedure

&AtClientAtServerNoContext
Function TitleText(Number, Date)
	
	 Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Kế hoạch mua hàng %1 ngày %2';
																			|ru = 'План закупок %1 от %2';
																			|en = 'Purchase plan %1 dated %2'; fa = 'Purchase plan %1 dated %2';
																			|it = 'План закупок %1 от %2';
																			|pl = 'Purchase plan %1 dated %2';
																			|tr = 'Satın alma planı %1 itibarıyla %2'"), Number, Date);
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form,CountLines = True)

	Object = Form.Object;
	Goods = Form.GoodsByPeriod;
	
	If CountLines Then
		LineNumber = 0;
		For Each TSRow In Goods Do
			LineNumber = LineNumber + 1;
			TSRow.LineNumber = LineNumber;
			TSRow.NumberOfPackages = 0;
			TSRow.Sum = 0;
			For Each PeriodString_ In Form.TimeIntervals Do
				TSRow["Price_" + PeriodString_.ColumnName] = TSRow.Price;
			EndDo;
		EndDo;
	EndIf;
	
	Form["NumberOfPackages"] = 0;
	Object.DocumentAmount = 0;
	
	Count = 0;
	Sum = 0;
	For Each PeriodString_ In Form.TimeIntervals Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf;
		
		Form["ProductsByPeriodQuantity_" + PeriodString_.ColumnName] = 0;
		Form["GoodsByPeriodSum_" + PeriodString_.ColumnName] = 0;
		For Each TSRow In Goods Do
			
			If CountLines Then
				TSRow.NumberOfPackages = TSRow.NumberOfPackages + TSRow["Count_" + PeriodString_.ColumnName];
				TSRow["Sum_" + PeriodString_.ColumnName] = TSRow["Count_" 
				                                    + PeriodString_.ColumnName] * TSRow["Price_" + PeriodString_.ColumnName];
				TSRow.Sum = TSRow.Sum + TSRow["Sum_" + PeriodString_.ColumnName];
			EndIf;
			Form["ProductsByPeriodQuantity_" + PeriodString_.ColumnName] = Form["ProductsByPeriodQuantity_" 
			                                + PeriodString_.ColumnName] + TSRow["Count_" + PeriodString_.ColumnName];
			Form["GoodsByPeriodSum_" + PeriodString_.ColumnName] = Form["GoodsByPeriodSum_" 
			                                + PeriodString_.ColumnName] + TSRow["Sum_" + PeriodString_.ColumnName];
		EndDo;
		
	EndDo;
	
	For Each TSRow In Goods Do
		Form["NumberOfPackages"] = Form["NumberOfPackages"] + TSRow["NumberOfPackages"];
		Object.DocumentAmount = Object.DocumentAmount + TSRow["Sum"];
	EndDo;
	
	Form.GoodsQuantity = Form.GoodsByPeriod.Count();
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure WriteToServer(CachedValues, Cancel)
	
	If Not CheckFilling() Then
		Cancel = True;
		Return;
	EndIf;
	
	ChangeTablePresentation(CachedValues, False);
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Write(DocumentWriteMode.Posting);
	Modified = False;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		SearchParameters = New Structure("Products, Characteristic", RowOfProduct.Products, RowOfProduct.Characteristic);
		If GoodsByPeriod.FindRows(SearchParameters).Count() > 0 Then
			Continue;
		EndIf;
		
		CurrentRow = GoodsByPeriod.Add();
		FillPropertyValues(CurrentRow, RowOfProduct,
		                         "Products, Characteristic, ItemVariantsAreUsed, Package, Price");
		
		If ThisForm.TimeIntervals.Count() > 0 Then
			CurrentRow["Count_" + ThisForm.TimeIntervals[0].ColumnName] = RowOfProduct.NumberOfPackages;
			CurrentRow.NumberOfPackages = RowOfProduct.NumberOfPackages;
		EndIf;
		
		For Each Period In ThisForm.TimeIntervals Do
			CurrentRow["Price_" + Period.ColumnName] = CurrentRow.Price;
		EndDo;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		GoodsByPeriod,
		CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
				New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Goods,
		StructureOfActions);
	
	CalculateTotals_(ThisForm);
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure ProcessChangesToPeriodInHeader()
	
	PlanningClientServer.SetStartEndOfPlanPeriod(Object.Periodicity, 
		Object.BeginOfPeriod, 
		Object.PeriodEnding,
		CommonClient.SessionDate());
	
	If YouNeedToUpdateInterface() Then
		
		PeriodChangedCorrectly();
		
	EndIf;
	
EndProcedure

// This function checks whether the interface needs to be updated when parameters are changed
//
&AtClient
Function YouNeedToUpdateInterface()
	
	If PeriodStartBeforeChanging <> Object.BeginOfPeriod Then
		Return True;
	EndIf; 
	
	If PeriodEndBeforeChange <> Object.PeriodEnding Then
		Return True;
	EndIf; 
	
	Return False;
	
EndFunction

&AtClient
Procedure PeriodChangedCorrectly()

	If GoodsByPeriod.Count() > 0 Then
		AskAQuestion = False;
		
		If PeriodStartBeforeChanging <> Object.BeginOfPeriod And Object.BeginOfPeriod > PeriodStartBeforeChanging Then
			AskAQuestion = True;
		EndIf; 
		
		If PeriodEndBeforeChange <> Object.PeriodEnding And Object.PeriodEnding < PeriodEndBeforeChange Then
			AskAQuestion = True;
		EndIf;
		
		If AskAQuestion Then
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa kỳ';
													|ru = 'Удалить периоды';
													|en = 'Remove periods'; fa = 'Remove periods';
													|it = 'Eliminare periodi';
													|pl = 'Usuń okresy';
													|tr = 'Dönemleri sil'"));
			Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ việc thay đổi kỳ';
													|ru = 'Отменить изменение периода';
													|en = 'Cancel period change'; fa = 'Cancel period change';
													|it = 'Annullare la modifica del periodo';
													|pl = 'Anuluj zmianę okresu';
													|tr = 'Dönem değişikliklerini iptal et'"));
			Response = Undefined;
			
			ShowQueryBox(
				New CallbackDescription("PeriodChangedCorrectlyCompletion", ThisObject), 
				NStr("vi = 'Thay đổi kỳ kế hoạch sẽ làm xóa dữ liệu của nhiều kỳ. Xóa các kỳ?';
					|ru = 'Изменение периода плана приведет к удалению данных в некоторых периодах. Удалить периоды?';
					|en = 'Plan period change will lead to data deletion in some periods. Delete the periods?'; fa = 'Plan period change will lead to data deletion in some periods. Delete the periods?';
					|it = 'La modifica del periodo del piano causerà l''eliminazione dei dati in alcuni periodi. Eliminare i periodi?';
					|pl = 'Zmiana okresu planu spowoduje usunięcie danych w niektórych okresach. Usunąć okresy?';
					|tr = 'Plan döneminin değiştirilmesi, bazı dönem verilerinin silinmesine sebep olacak. Dönemler silinsin mi?'"), 
				Buttons);
			Return;
			
		EndIf; 
	
	EndIf; 
	
	WhenChangingPeriodsOnServer();

EndProcedure

&AtClient
Procedure PeriodChangedCorrectlyCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		WhenChangingPeriodsOnServer();
	Else
		Object.BeginOfPeriod = PeriodStartBeforeChanging;
		Object.PeriodEnding = PeriodEndBeforeChange;
	EndIf;

EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductInCollection()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
				New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInArticleAttribute",
				New Structure("Products", "SKU"));
				
	ProductsServer.FillInServiceDetailsForProductInCollection(
		GoodsByPeriod,
		StructureOfActions);

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	If Not Object.Terms.IsEmpty() Then
		
		PlanProfileOnChangeServer();
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	TermsOfSale.Warehouse,
		|	ISNULL(Warehouses.IsFolder, FALSE) AS ThisIsWarehouseGroup,
		|	TermsOfSale.ProductSegment
		|FROM
		|	Catalog.TermsOfSale AS TermsOfSale
		|		LEFT JOIN Catalog.Warehouses AS Warehouses
		|		ON TermsOfSale.Warehouse = Warehouses.Ref
		|WHERE
		|	TermsOfSale.Ref = &Terms";
		
		Query.SetParameter("Terms", Object.Terms);
		Query.SetParameter("Partner", Object.Partner);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		ProductSegment = Selection.ProductSegment;
		AvailabilityManagementChangeOfAgreement(Selection);
	Else
		AvailabilityManagementChangeOfAgreement(Undefined);
	EndIf;
	
	UsePaymentSchedules = GetFunctionalOption("UsePaymentSchedules");
	
	AgreementWhenModifiedOnServer();
	
	Planning.CreatePeriodTable(ThisForm, "TimeIntervals");
	
	WhenChangingPeriodsOnServer();
	
	ChangeTablePresentation(Undefined);
	
	AvailabilityControl(ThisForm);
	
	CalculatePaymentPlanTotals(ThisForm);
	
EndProcedure

&AtServerNoContext
Function GetPlanViewParameters(Val PlanProfile)
	
	PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, "FillInBusinessUnit, FillInPartner,
		|FillInPartnerInTabularForm, FillInTermsOfSales, FillInAgreementInTabularForm, FillInWarehouse, FillInWarehouseInTabularForm, 
		|FillInUsingFormula, FillInPaymentPlan");
	
	Return PlanViewParameters;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateRelatedItemDetails(Object, Form)
	
	If Not Form.FillInWarehouse Then
		Object.Warehouse = Undefined;
	EndIf;

EndProcedure

// The procedure changes the presentation of the data of the tabular part into a cross-table and vice versa.
//
// Parameters:
//  CachedValues  - Structure - values cached for the form
//  InCrossTable  - Boolean - Flag for transferring a table to a cross-table and vice versa.
//
&AtServer
Procedure ChangeTablePresentation(CachedValues, InCrossTable = True, UpdatePeriods = False)
	
	If UpdatePeriods Then
		WhenChangingPeriodsOnServer();
	EndIf;
	
	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	
	StructureOfPeriodDetails = New Structure("StartDate","DateOfShipment");
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Count_","NumberOfPackages");
	AttributesStructure1.Insert("Price_","Price");
	AttributesStructure1.Insert("Sum_","Sum");
	
	GroupFields = "Products, Characteristic, Package, Warehouse, Partner, Terms";
	
	StructureOfFinalDetails = New Structure;
	StructureOfFinalDetails.Insert("NumberOfPackages", "NumberOfPackages");
	StructureOfFinalDetails.Insert("Sum", "Sum");
	
	ConversionParameters = New Structure;
	ConversionParameters.Insert("TablePeriods",              TablePeriods);
	ConversionParameters.Insert("Periodicity",               Object.Periodicity);
	ConversionParameters.Insert("StructureOfPeriodDetails",  StructureOfPeriodDetails);
	ConversionParameters.Insert("AttributesStructure1",         AttributesStructure1);
	ConversionParameters.Insert("GroupFields",             GroupFields);
	ConversionParameters.Insert("StructureOfFinalDetails", StructureOfFinalDetails);
	
	If InCrossTable Then
		
		Goods = Object.Goods.FindRows(New Structure("Canceled", False));
		For Each TSRow In Goods Do
			If Not ValueIsFilled(TSRow.DateOfShipment) Then
				TSRow.DateOfShipment = Object.BeginOfPeriod;
			EndIf;
		EndDo;
		
		PlanningClientServer.FillInCrossTableFromTable(GoodsByPeriod, Goods, ConversionParameters);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		
		BatchProcessingOfTablePartServer.TreatTS(GoodsByPeriod, StructureOfActions, CachedValues);
		
		CalculateTotals_(ThisForm);
		
	Else
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		StructureOfActions.Insert("RecalculateAmount");
		
		Planning.FillInTableFromCrossTable(Object.Goods, Object.Goods, GoodsByPeriod, ConversionParameters, 
			StructureOfActions, CachedValues);
	
	EndIf;
		
	FillInServiceDetailsForProductInCollection();

EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
EndProcedure

&AtClient
Procedure OpenProductItemCard()

	CurrentData = Items.GoodsByPeriod.CurrentData;
	
	If CurrentData <> Undefined Then
		FormParameters = New Structure("Key", CurrentData.Products);
		OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
	EndIf;

EndProcedure

&AtClient
Procedure WhenChangingAmountOfRowSum(Object, RowOfGoods, CachedValues)

	Count = 0;
	Sum = 0;
	For Each PeriodString_ In ThisForm.TimeIntervals Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf;
		
		Count = Count + RowOfGoods["Count_" + PeriodString_.ColumnName];
		If Object.PlanByAmount Then
			RowOfGoods["Sum_" + PeriodString_.ColumnName] = RowOfGoods["Count_" + PeriodString_.ColumnName] * RowOfGoods["Price"];
		Else
			RowOfGoods["Sum_" + PeriodString_.ColumnName] = 0;
		EndIf; 
		
		Sum = Sum + RowOfGoods["Sum_" + PeriodString_.ColumnName];
		
	EndDo;
	
	RowOfGoods.NumberOfPackages = Count;
	RowOfGoods.Sum              = Count * RowOfGoods.Price;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, StructureOfActions, CachedValues);

	CalculateTotals_(ThisForm, False);

EndProcedure

&AtClient
Procedure OpenProductSelectionForm_1()

	FormParameters = New Structure;
	FormParameters.Insert("TransferHeader",                NStr("vi = 'Chuyển vào chứng từ';
																|ru = 'Перенести в документ';
																|en = 'Add to document'; fa = 'افزودن به سند';
																|it = 'Trasferire nel documento';
																|pl = 'Przenieś do dokumentu';
																|tr = 'Belgeye taşı'"));
	FormParameters.Insert("Terms",                        Object.Terms);
	FormParameters.Insert("Warehouse",                             Object.Warehouse);
	FormParameters.Insert("Currency",                            Object.Currency);
	FormParameters.Insert("Title",                         NStr("vi = 'Chọn hàng hóa vào';
																|ru = 'Подбор товаров в';
																|en = 'Pick goods in'; fa = 'Pick goods in';
																|it = 'Selezione prodotti in';
																|pl = 'Wybór towarów w';
																|tr = 'İçindeki ürünlerin seçimi'") + " " 
	                                                             + TitleText(Object.Number, Object.Date));
	FormParameters.Insert("ProductSegment",               ProductSegment);
	FormParameters.Insert("BusinessOperation",             BusinessOperation);
	FormParameters.Insert("VATTaxation",                VATTaxation);
	FormParameters.Insert("Document",                          Object.Ref);
	FormParameters.Insert("Date",                              Object.BeginOfPeriod);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",   ?(BalanceViewIsAvailable, False, True));
	FormParameters.Insert("SelectionModeWithoutAmountParameters", ?(Object.PlanByAmount, False, True));
	FormParameters.Insert("PriceIncludesVAT",                   PriceIncludesVAT);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form",
	             SelfServiceClient.StructureOfParametersForSelection(FormParameters),
	             ThisForm, UUID);

EndProcedure

#EndRegion

#Region PaymentPlan_

&AtClientAtServerNoContext
Procedure CalculatePaymentPlanTotals(Form)
	
	GeneralTotalPaymentAmount = 0;
	Form.LineNumberOfFullPayment = 0;
	For Each CurRow In Form.Object.CashFlowPlan Do
		
		GeneralTotalPaymentAmount = GeneralTotalPaymentAmount + CurRow.PaymentAmount;
		CurRow.PaymentAmountIsFilledInIncorrectly = (GeneralTotalPaymentAmount > Form.Object.DocumentAmount);
		If GeneralTotalPaymentAmount = Form.Object.DocumentAmount Then
			Form.LineNumberOfFullPayment = CurRow.LineNumber;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure BeforeWriteCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
		If AdditionalParameters.Property("ClearPaymentPlan") And AdditionalParameters.ClearPaymentPlan Then
			Object.CashFlowPlan.Clear();
		EndIf;
		
		If AdditionalParameters.Property("ReFillStages") And AdditionalParameters.ReFillStages Then
			FillOutPaymentPlan(AdditionalParameters.AgreementScheduleIsFilledIn, AdditionalParameters.ScheduleIsFull);
		EndIf;
		
		Write();
	Else
		RepeatCallBeforeRecording = False;
	EndIf; 
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Items.PaymentGroup_2.Visible = Object.FillInPaymentPlan;
	Items.PictureAllowableDebtAmount.Visible = LimitDebtAmount;
	Items.LabelAvailableDebtAmount.Visible = LimitDebtAmount;
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	If ValueIsFilled(Object.Contract) Then
	
		ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, 
			"LimitDebtAmount, AllowableAmountPayable");
		FillPropertyValues(ThisForm, ContractDetails_);
	
	Else
	
		LimitDebtAmount  = False;
		AllowableAmountPayable = 0;
	
	EndIf;
	
	LabelAvailableDebtAmount = LabelAvailableDebtAmount(AllowableAmountPayable, Object.Currency);
	
	SetVisibility1();
	
EndProcedure

&AtClientAtServerNoContext
Function LabelAvailableDebtAmount(DebtAmount, Currency)

	LabelAvailableDebtAmount = NStr("vi = 'Số tiền công nợ hợp lệ không lớn hơn: %DebtAmount% %Currency%.';
									|ru = 'Допустимая сумма задолженности не более: %DebtAmount% %Currency%.';
									|en = 'Allowable debt amount no more than: %DebtAmount% %Currency%.'; fa = 'Allowable debt amount no more than: %DebtAmount% %Currency%.';
									|it = 'L''ammontare dell''indebitamento ammissibile non superiore: %DebtAmount% %Currency%.';
									|pl = 'Dopuszczalna wartość zobowiązania nie jest większa niż: %DebtAmount%%Currency%.';
									|tr = 'İzin verilen borç tutarı şu kadarı aşmamalıdır: %DebtAmount% %Currency%.'");
	LabelAvailableDebtAmount = StrReplace(LabelAvailableDebtAmount, "%DebtAmount%", String(DebtAmount));
	LabelAvailableDebtAmount = StrReplace(LabelAvailableDebtAmount, "%Currency%", Currency);
	
	Return LabelAvailableDebtAmount;

EndFunction 

&AtClient
Procedure FillInPaymentScheduleStepsCompletion(Result, AdditionalParameters) Export 

	If Result = DialogReturnCode.Yes Then
		
		FillOutPaymentPlan(AdditionalParameters.AgreementScheduleIsFilledIn, AdditionalParameters.ScheduleIsFull);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillOutPaymentPlan(AgreementScheduleIsFilledIn, ScheduleIsFull)
	
	If AgreementScheduleIsFilledIn Or ScheduleIsFull Then
		
		FillInPaymentStagesUsingServerTemplate(AgreementScheduleIsFilledIn, ScheduleIsFull);
		
	Else
		
		Object.CashFlowPlan.Clear();
		
		If Object.CrossTable Then
			
			AmountByPayments = 0;
			AmountByShipments = 0;
			TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
			
			For Each Period In TablePeriods Do
				
				If Not Period.Active_ Or Period.ColumnNumber = 0 Then
					Continue;
				EndIf; 
				
				PaymentAmountForPeriod = ThisForm["GoodsByPeriodSum_"+Period.ColumnName];
				AmountByShipments = AmountByShipments + PaymentAmountForPeriod;
				
				PaymentStage = Object.CashFlowPlan.Add();
				PaymentStage.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment");
				PaymentStage.PaymentDate = Period.StartDate;
				PaymentStage.PaymentAmount = PaymentAmountForPeriod;
				
				PaymentStage.AmountByShipments = AmountByShipments;
				PaymentStage.AmountByPayments = AmountByPayments;
				
				AmountByPayments = AmountByPayments + PaymentStage.PaymentAmount;
				
				PaymentStage.DebtAmount = PaymentStage.AmountByShipments - AmountByPayments;
				PaymentStage.PaymentPercentage = ?(PaymentStage.AmountByShipments > 0, 100 * PaymentStage.PaymentAmount / PaymentStage.AmountByShipments, 0);
				
			EndDo;
			
			CalculatePaymentPlanTotals(ThisForm);
			
		Else
			
			AddDefaultPaymentStageServer();
			
		EndIf; 
		
	EndIf;
	
	PaymentStepsClient.NotifyEndOfFillingInStagesOfPaymentSchedule();
	
EndProcedure

&AtServer
Procedure FillInPaymentStagesUsingServerTemplate(AgreementScheduleIsFilledIn, ScheduleIsFull)
	
	Object.CashFlowPlan.Clear();
	
	CashFlowPlan = Object.CashFlowPlan.Unload();
	PaymentPlanCopy = CashFlowPlan.Copy();
	
	If ScheduleIsFull And Object.PaymentScheduleSteps.Count() > 0 Then
	
		ScheduleTemplate = Object.PaymentScheduleSteps;
		Calendar = Object.Calendar;
	
	ElsIf ScheduleIsFull And ValueIsFilled(Object.PaymentSchedule) Then
		Query = New Query(
		"SELECT
		|	PaymentSchedulesStages.LineNumber         AS LineNumber,
		|	PaymentSchedulesStages.PaymentOption       AS PaymentOption,
		|	PaymentSchedulesStages.Move               AS Move,
		|	PaymentSchedulesStages.PaymentPercentage      AS PaymentPercentage,
		|	PaymentSchedulesStages.PackageDepositPercentage AS PackageDepositPercentage,
		|	PaymentSchedulesStages.Ref.Calendar    AS Calendar,
		|	PaymentSchedulesStages.Ref.PaymentMethod  AS PaymentMethod
		|FROM
		|	Catalog.PaymentSchedules.Stages AS PaymentSchedulesStages
		|WHERE
		|	PaymentSchedulesStages.Ref = &PaymentSchedule
		|ORDER BY
		|	LineNumber ASC
		|");
		
		Query.SetParameter("PaymentSchedule", Object.PaymentSchedule);
		
		QueryResult = Query.Execute();
		ScheduleTemplate    = QueryResult.Unload();
		Calendar        = ScheduleTemplate[0].Calendar;

	Else
		Query = New Query(
		"SELECT
		|	TermsOfSalePaymentScheduleSteps.LineNumber AS LineNumber,
		|	TermsOfSalePaymentScheduleSteps.PaymentOption AS PaymentOption,
		|	TermsOfSalePaymentScheduleSteps.Formula AS Formula,
		|	TermsOfSalePaymentScheduleSteps.CalculateFrom AS CalculateFrom,
		|	TermsOfSalePaymentScheduleSteps.Move AS Move,
		|	TermsOfSalePaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
		|	TermsOfSalePaymentScheduleSteps.PackageDepositPercentage AS PackageDepositPercentage,
		|	TermsOfSalePaymentScheduleSteps.Ref.PaymentMethod AS PaymentMethod,
		|	TermsOfSalePaymentScheduleSteps.Ref.Calendar AS Calendar
		|FROM
		|	Catalog.TermsOfSale.PaymentScheduleSteps AS TermsOfSalePaymentScheduleSteps
		|WHERE
		|	TermsOfSalePaymentScheduleSteps.Ref = &Terms
		|
		|ORDER BY
		|	LineNumber");
		
		Query.SetParameter("Terms", Object.Terms);
		
		QueryResult = Query.Execute();
		ScheduleTemplate    = QueryResult.Unload();
		Calendar        = ScheduleTemplate[0].Calendar;
		
	EndIf; 
	
	If Object.CrossTable Then
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
			
		For Each Period In TablePeriods Do
			If Not Period.Active_ Or Period.ColumnNumber = 0 Then
				Continue;
			EndIf;
			
			AmountOfPaymentToBeDistributed = ThisForm["GoodsByPeriodSum_"+Period.ColumnName];
			
			FillParameters = PaymentStepsServer.ParametersForFillingInPaymentStages();
			FillParameters.TheseAreSettlementsWithCustomers = True;
			FillParameters.InvoiceForOrders = False;
			FillParameters.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders;
			FillParameters.ThisIsOrder = False;
			
			FillParameters.Insert("DateOfShipment", Period.StartDate);
			FillParameters.Insert("OrderDate", Period.StartDate);
			FillParameters.Insert("ScheduleTemplate", ScheduleTemplate);
			FillParameters.Insert("Calendar", Calendar);
			FillParameters.Insert("PayAmount", AmountOfPaymentToBeDistributed);
			
			PaymentStepsServer.FillInPaymentStagesOfDocumentUsingTemplate(PaymentPlanCopy, FillParameters);
			
			For Each PaymentStage In PaymentPlanCopy Do
				
				NewRow = CashFlowPlan.Add();
				FillPropertyValues(NewRow, PaymentStage);
				
			EndDo; 
			
		EndDo; 
		
		CashFlowPlan.GroupBy("PaymentOption, PaymentDate","PaymentAmount, DebtAmount, AmountByShipments");
		CashFlowPlan.Columns.Add("PaymentPercentage");
		CashFlowPlan.Columns.Add("AmountByPayments");
		CashFlowPlan.Sort("PaymentDate");
		
		AmountByPayments = 0;
		For Each PaymentStage In CashFlowPlan Do
			TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
			
			For Each Period In TablePeriods Do
				If Not Period.Active_ Or Period.ColumnNumber = 0 Or PaymentStage.PaymentDate < Period.StartDate Then
					Continue;
				EndIf;
				
				PaymentStage.AmountByShipments = PaymentStage.AmountByShipments + ThisForm["GoodsByPeriodSum_"+Period.ColumnName];
			EndDo;
			
			PaymentStage.AmountByPayments = AmountByPayments;
			AmountByPayments = AmountByPayments + PaymentStage.PaymentAmount;
			PaymentStage.DebtAmount = PaymentStage.AmountByShipments - AmountByPayments;
			PaymentStage.PaymentPercentage = ?(PaymentStage.AmountByShipments > 0, 100 * PaymentStage.PaymentAmount / PaymentStage.AmountByShipments, 0);
			
		EndDo; 
		
	Else
	
		AmountsByDate = Object.Goods.Unload(,"DateOfShipment, Sum");
		AmountsByDate.GroupBy("DateOfShipment", "Sum");
		AmountsByDate.Sort("DateOfShipment");
		
		For Each AmountAsOfDate In AmountsByDate Do
			
			AmountOfPaymentToBeDistributed = AmountAsOfDate.Sum;
			
			FillParameters = PaymentStepsServer.ParametersForFillingInPaymentStages();
			FillParameters.TheseAreSettlementsWithCustomers = True;
			FillParameters.InvoiceForOrders = False;
			FillParameters.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders;
			FillParameters.ThisIsOrder = False;
			
			FillParameters.Insert("DateOfShipment", Period.StartDate);
			FillParameters.Insert("OrderDate", Period.StartDate);
			FillParameters.Insert("ScheduleTemplate", ScheduleTemplate);
			FillParameters.Insert("Calendar", Calendar);
			FillParameters.Insert("PayAmount", AmountOfPaymentToBeDistributed);
			
			PaymentStepsServer.FillInPaymentStagesOfDocumentUsingTemplate(CashFlowPlan, FillParameters);
			 
		EndDo;
		
		CashFlowPlan.GroupBy("PaymentOption, PaymentDate","PaymentAmount, DebtAmount, AmountByShipments");
		CashFlowPlan.Columns.Add("PaymentPercentage");
		CashFlowPlan.Columns.Add("AmountByPayments");
		CashFlowPlan.Sort("PaymentDate");
		
		AmountByPayments = 0;
		For Each PaymentStage In CashFlowPlan Do
			
			For Each AmountAsOfDate In AmountsByDate Do
				
				If PaymentStage.PaymentDate < AmountAsOfDate.DateOfShipment Then
					Continue;
				EndIf;
				PaymentStage.AmountByShipments = PaymentStage.AmountByShipments + AmountAsOfDate.Sum;
			EndDo; 
			
			PaymentStage.AmountByPayments = AmountByPayments;
			AmountByPayments = AmountByPayments + PaymentStage.PaymentAmount;
			
			PaymentStage.DebtAmount = PaymentStage.AmountByShipments - AmountByPayments;
			PaymentStage.PaymentPercentage = ?(PaymentStage.AmountByShipments > 0, 100 * PaymentStage.PaymentAmount / PaymentStage.AmountByShipments, 0);
		EndDo;
	EndIf; 
	
	Object.CashFlowPlan.Load(CashFlowPlan);
	
	CalculatePaymentPlanTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure AddDefaultPaymentStageServer()

	If Object.CrossTable Then
	
		Return;
	
	EndIf; 
	
	AmountsByDate = Object.Goods.Unload(,"DateOfShipment, Sum");
	AmountsByDate.GroupBy("DateOfShipment", "Sum");
	AmountsByDate.Sort("DateOfShipment");
	
	AmountByPayments = 0;
	AmountByShipments = 0;
	For Each AmountAsOfDate In AmountsByDate Do
		
		If AmountAsOfDate.Sum = 0 Then
			Continue;
		EndIf; 
		
		AmountByShipments = AmountByShipments + AmountAsOfDate.Sum;
		
		PaymentStage = Object.CashFlowPlan.Add();
		PaymentStage.PaymentOption = Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment;
		PaymentStage.PaymentDate = AmountAsOfDate.DateOfShipment;
		PaymentStage.PaymentAmount = AmountAsOfDate.Sum;
		
		PaymentStage.AmountByShipments = AmountByShipments;
		PaymentStage.AmountByPayments = AmountByPayments;
		
		AmountByPayments = AmountByPayments + PaymentStage.PaymentAmount;
		
		PaymentStage.DebtAmount = PaymentStage.AmountByShipments - AmountByPayments;
		PaymentStage.PaymentPercentage = ?(PaymentStage.AmountByShipments > 0, 100 * PaymentStage.PaymentAmount / PaymentStage.AmountByShipments, 0);
		
	EndDo;
	
	CalculatePaymentPlanTotals(ThisForm);

EndProcedure 

&AtClient
Procedure RecalculatePaymentPlanAmountsByLine(PaymentPlanLine)

	AmountByPayments = 0;
	For Each PaymentStage In Object.CashFlowPlan Do
	
		If PaymentStage.PaymentDate <= PaymentPlanLine.PaymentDate Then
			AmountByPayments = AmountByPayments + PaymentStage.PaymentAmount;
			Continue;
		EndIf; 
		
		PaymentStage.AmountByPayments = AmountByPayments;
		AmountByPayments = AmountByPayments + PaymentStage.PaymentAmount;
		PaymentStage.DebtAmount = PaymentStage.AmountByShipments - AmountByPayments;
		
	EndDo; 

EndProcedure

#EndRegion 

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_PeriodEnding" Then
		PeriodEndingOnChange(Items.PeriodEnding);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
