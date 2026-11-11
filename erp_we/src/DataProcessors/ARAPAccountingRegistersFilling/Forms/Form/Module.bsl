
#Region FormCommandsEventHandlers

&AtClient
Procedure FillInBySpecified(Command)
	QueryText = StrTemplate(NStr("vi = 'Theo dữ liệu của bản ghi kết chuyển gốc, sẽ điền lại các biểu ghi: %1
	|
	|Nhiệm vụ phản ánh lại vào KTDN, Kế toán quốc tế, thuế GTGT và chưa tạo đóng tháng. Tiếp tục?';
	|ru = 'По данным первичных движений будут перезаполнены регистры: %1
	|
	|Задания к переотражению в БУ, МФУ, НДС и к закрытию месяца созданы не будут. Продолжить?';
	|en = 'The following registers will be re-populated: %1 according to the primary register records data
	|
	|Jobs to be recorded in the local accounting, IFRS, VAT and by the month-end closing will not be created. Continue?'; fa = 'The following registers will be re-populated: %1 according to the primary register records data
	|
	|Jobs to be recorded in the local accounting, IFRS, VAT and by the month-end closing will not be created. Continue?';
	|it = 'I registri saranno ricompilati in base ai dati di movimenti primari: %1
	|
	|I task di ri-registrazione in contabilità ordinaria, contabilità finanziaria internazionale, IVA e alla chiusura del mese non saranno creati. Continuare?';
	|pl = 'Wg danych pierwotnych przepływów zostaną ponownie wypełnione rejestry: %1
	|
	|Zadania do ponownego odzwierciedlenia w ewidencji księgowej, międzynarodowej ewidencji księgowej, VAT i do zamknięcia miesiąca nie będą utworzone. Kontynuować?';
	|tr = 'Birincil hareketlerin verilerine göre, kayıtlar yeniden doldurulacaktır: %1
	|
	| AC, UFM, KDV''de yeniden raporlama ve ay sonu kapanışı için görevler oluşturulmayacaktır. Devam edilsin mi?'"),
		RegisterNames());
	ShowQueryBox(New CallbackDescription("FillInBySpecifiedCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure FillInBySpecifiedCompletion(QuestionResult, AdditionalParameters) Export
	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		Message(NStr("vi = 'Bắt đầu giao dịch:';
					|ru = 'Начало операции:';
					|en = 'Operation start:'; fa = 'Operation start:';
					|it = 'Inizio operazione:';
					|pl = 'Początek operacji:';
					|tr = 'İşlem başlangıcı:'") + " " + CurrentDate());
		FillBySpecifiedOnServer();
		Message(NStr("vi = 'Đã thực hiện giao dịch thành công:';
					|ru = 'Операция выполнена успешно:';
					|en = 'Operation has been successfully installed:'; fa = 'Operation has been successfully installed:';
					|it = 'Operazione completata con successo:';
					|pl = 'Operacja została wykonana pomyślnie:';
					|tr = 'İşlem başarıyla tamamlandı:'") + " " + CurrentDate());
	EndIf;
EndProcedure

&AtClient
Procedure Clear(Command)
	ClearMessages();
	Message(NStr("vi = 'Bắt đầu giao dịch:';
				|ru = 'Начало операции:';
				|en = 'Operation start:'; fa = 'Operation start:';
				|it = 'Inizio operazione:';
				|pl = 'Początek operacji:';
				|tr = 'İşlem başlangıcı:'") + " " + CurrentDate());
	ClearAtServer();
	Message(NStr("vi = 'Đã thực hiện giao dịch thành công:';
				|ru = 'Операция выполнена успешно:';
				|en = 'Operation has been successfully installed:'; fa = 'Operation has been successfully installed:';
				|it = 'Operazione completata con successo:';
				|pl = 'Operacja została wykonana pomyślnie:';
				|tr = 'İşlem başarıyla tamamlandı:'") + " " + CurrentDate());
EndProcedure

&AtClient
Procedure FillInAll(Command)
	QueryText = StrTemplate(NStr("vi = 'Theo dữ liệu của bản ghi kết chuyển gốc, sẽ điền lại các biểu ghi: %1
	|
	|Nhiệm vụ phản ánh lại vào KTDN, Kế toán quốc tế, thuế GTGT và chưa tạo đóng tháng. Tiếp tục?';
	|ru = 'По данным первичных движений будут перезаполнены регистры: %1
	|
	|Задания к переотражению в БУ, МФУ, НДС и к закрытию месяца созданы не будут. Продолжить?';
	|en = 'The following registers will be re-populated: %1 according to the primary register records data
	|
	|Jobs to be recorded in the local accounting, IFRS, VAT and by the month-end closing will not be created. Continue?'; fa = 'The following registers will be re-populated: %1 according to the primary register records data
	|
	|Jobs to be recorded in the local accounting, IFRS, VAT and by the month-end closing will not be created. Continue?';
	|it = 'I registri saranno ricompilati in base ai dati di movimenti primari: %1
	|
	|I task di ri-registrazione in contabilità ordinaria, contabilità finanziaria internazionale, IVA e alla chiusura del mese non saranno creati. Continuare?';
	|pl = 'Wg danych pierwotnych przepływów zostaną ponownie wypełnione rejestry: %1
	|
	|Zadania do ponownego odzwierciedlenia w ewidencji księgowej, międzynarodowej ewidencji księgowej, VAT i do zamknięcia miesiąca nie będą utworzone. Kontynuować?';
	|tr = 'Birincil hareketlerin verilerine göre, kayıtlar yeniden doldurulacaktır: %1
	|
	| AC, UFM, KDV''de yeniden raporlama ve ay sonu kapanışı için görevler oluşturulmayacaktır. Devam edilsin mi?'"),
		RegisterNames());
	ShowQueryBox(New CallbackDescription("FillInAllCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure FillInAllCompletion(QuestionResult, AdditionalParameters) Export
	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		Message(NStr("vi = 'Bắt đầu giao dịch:';
					|ru = 'Начало операции:';
					|en = 'Operation start:'; fa = 'Operation start:';
					|it = 'Inizio operazione:';
					|pl = 'Początek operacji:';
					|tr = 'İşlem başlangıcı:'") + " " + CurrentDate());
		FillInAllServer();
		Message(NStr("vi = 'Đã thực hiện giao dịch thành công:';
					|ru = 'Операция выполнена успешно:';
					|en = 'Operation has been successfully installed:'; fa = 'Operation has been successfully installed:';
					|it = 'Operazione completata con successo:';
					|pl = 'Operacja została wykonana pomyślnie:';
					|tr = 'İşlem başarıyla tamamlandı:'") + " " + CurrentDate());
	EndIf;
EndProcedure

&AtClient
Procedure FillInScheduled(Command)
	QueryText = StrTemplate(NStr("vi = 'Theo dữ liệu bản ghi kết chuyển gốc sẽ điền lại biểu ghi: %1
	|
	|Tiếp tục?';
	|ru = 'По данным первичных движений будут перезаполнены регистры: %1
	|
	|Продолжить?';
	|en = 'The following registers will be re-populated: %1 according to the primary register records data
	|
	|. Continue?'; fa = 'The following registers will be re-populated: %1 according to the primary register records data
	|
	|. Continue?';
	|it = 'I registri saranno ricompilati in base ai dati di movimenti primari: %1
	|
	|Continuare?';
	|pl = 'Wg danych pierwotnych przepływów zostaną ponownie wypełnione rejestry: %1
	|
	|Kontynuować?';
	|tr = 'Kayıtlar ilk hareketlerin verilerine göre yeniden doldurulacaktır: %1
	|
	|Devam edilsin mi?'"),
		RegisterNames(True));
	ShowQueryBox(New CallbackDescription("FillInScheduledCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure FillInScheduledCompletion(QuestionResult, AdditionalParameters) Export
	If QuestionResult = DialogReturnCode.Yes Then
		FillInScheduledTasksOnServer();
	EndIf;
EndProcedure

&AtClient
Procedure AnalyticsOfCalculationsByTermsForRecalculation(Command)
	
	OpenForm("DataProcessor.ARAPAccountingRegistersFilling.Form.CalculationDimensionForRecalculationForm");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillBySpecifiedOnServer(Order = "")
	
	Query = New Query;
	Query.SetParameter("AccountingDimensionByPartners",DimensionKeyOfAccountingByPartners);
	Query.SetParameter("ARAPObject",ARAPObject);
	Query.SetParameter("RecalculationStartDate",RecalculationStartDate);
	
	Query.Text = "
	|SELECT DISTINCT
	|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency         AS Currency,
	|	&RecalculationStartDate   AS RecalculationStartDate,
	|	DATETIME(3999,1,1)    AS PeriodForMonitoringChangesAndCreatingTasks
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	TRUE
	|	AND Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.AccountingDimensionByPartners = &AccountingDimensionByPartners
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency         AS Currency,
	|	&RecalculationStartDate   AS RecalculationStartDate,
	|	DATETIME(3999,1,1)    AS PeriodForMonitoringChangesAndCreatingTasks
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	TRUE
	|	AND Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.AccountingDimensionByPartners = &AccountingDimensionByPartners
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency         AS Currency,
	|	&RecalculationStartDate   AS RecalculationStartDate,
	|	DATETIME(3999,1,1)    AS PeriodForMonitoringChangesAndCreatingTasks
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|WHERE
	|	TRUE
	|	AND Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.AccountingDimensionByPartners = &AccountingDimensionByPartners
	|
	|UNION
	|
	|SELECT DISTINCT
	|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency         AS Currency,
	|	&RecalculationStartDate   AS RecalculationStartDate,
	|	DATETIME(3999,1,1)    AS PeriodForMonitoringChangesAndCreatingTasks
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|WHERE
	|	TRUE
	|	AND Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.AccountingDimensionByPartners = &AccountingDimensionByPartners";
	
	If Not ValueIsFilled(ARAPObject) Then
		Query.Text = StrReplace(Query.Text,"Calculations.ARAPObject = &ARAPObject","TRUE");
	EndIf;
	
	If Not ValueIsFilled(DimensionKeyOfAccountingByPartners) Then
		Query.Text = StrReplace(Query.Text,"Calculations.AccountingDimensionByPartners = &AccountingDimensionByPartners","TRUE");
	EndIf;
	
	ObjectsTable = Query.Execute().Unload();
		
	If Not ValueIsFilled(RecalculationStartDate) Then
		ARAPAccountingInternal.ClearSettlementRegistersAndDeleteServiceRecorders(
			?(ValueIsFilled(ARAPObject), ARAPObject, Undefined),
			?(ValueIsFilled(DimensionKeyOfAccountingByPartners),DimensionKeyOfAccountingByPartners, Undefined));
	EndIf;
	
	MainParameters = OnlineARAPAccountingServer.CalculationDistributionParameters();
	MainParameters.SupplementDistributeReceivers = True;
	
	For Each TableRow In ObjectsTable Do
		
		If TableRow.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
			
			//Forced clearing of registers by time
			Query.Text = "
			|SELECT DISTINCT
			|	Register.Recorder AS Recorder
			|FROM
			|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Register
			|WHERE
			|	Register.Recorder REFS Document.RegisterAdjustment
			|	AND CAST(Register.Recorder AS Document.RegisterAdjustment).Operation <> VALUE(Enum.RegisterAdjustmentOperations.ManualAdjustment)
			|	AND Register.AccountingDimensionByPartners = &AccountingDimensionByPartners
			|	AND Register.ARAPObject = &ARAPObject
			|";
			Query.SetParameter("ARAPObject",ARAPObject);
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				DocumentObject = Selection.Recorder.GetObject();
				SettlementsWithClients_ = DocumentObject.RegisterRecords.CustomersARAPAccountingByDueDates;
				SettlementsWithClients_.Read();
				RowIndex = 0;
				While RowIndex < SettlementsWithClients_.Count() Do
					If SettlementsWithClients_[RowIndex].AccountingDimensionByPartners = DimensionKeyOfAccountingByPartners
						And SettlementsWithClients_[RowIndex].ARAPObject = ARAPObject Then
						SettlementsWithClients_.Delete(RowIndex);
					Else
						RowIndex = RowIndex + 1;
					EndIf;
				EndDo;
				SettlementsWithClients_.Write();
			EndDo;
			
		Else
			
			Query.Text = "
			|SELECT DISTINCT
			|	Register.Recorder AS Recorder
			|FROM
			|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Register
			|WHERE
			|	Register.Recorder REFS Document.RegisterAdjustment
			|	AND CAST(Register.Recorder AS Document.RegisterAdjustment).Operation <> VALUE(Enum.RegisterAdjustmentOperations.ManualAdjustment)
			|	AND Register.AccountingDimensionByPartners = &AccountingDimensionByPartners
			|	AND Register.ARAPObject = &ARAPObject
			|";
			Query.SetParameter("ARAPObject",ARAPObject);
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				DocumentObject = Selection.Recorder.GetObject();
				
				SettlementsWithSuppliers_ = DocumentObject.RegisterRecords.VendorsARAPAccountingByDueDates;
				SettlementsWithSuppliers_.Read();
				Cnt = 0;
				While Cnt < SettlementsWithSuppliers_.Count() Do
					If SettlementsWithSuppliers_[Cnt].AccountingDimensionByPartners = DimensionKeyOfAccountingByPartners
						And SettlementsWithSuppliers_[Cnt].ARAPObject = ARAPObject Then
						SettlementsWithSuppliers_.Delete(Cnt);
					Else
						Cnt = Cnt + 1;
					EndIf;
				EndDo;
				SettlementsWithSuppliers_.Write();
				
			EndDo;
			
		EndIf;
	EndDo;
	
	OnlineARAPAccountingServer.FillInOperationalARAPAccountsAccordingToTable(MainParameters, ObjectsTable);
	
EndProcedure

&AtServer
Procedure ClearAtServer()
	ARAPAccountingInternal.ClearSettlementRegisters();
EndProcedure

&AtServer
Procedure FillInAllServer()
	ARAPAccountingInternal.FillInAllCalculations();
EndProcedure

&AtServer
Procedure FillInScheduledTasksOnServer()
	
	ARAPAccountingInternal.FillInAllCalculations(True);
	
EndProcedure

&AtServer
Function RegisterNames(OnlyPlanned = False)
	If Not OnlyPlanned Then
		Return 
			StrTemplate("
			|	%1
			|	%2
			|	%3
			|	%4
			|	%5
			|	%6",
			Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Synonym,
			Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.Synonym,
			Metadata.AccumulationRegisters.CustomersARAPAccountingPlannedShipments.Synonym,
			Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Synonym,
			Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.Synonym,
			Metadata.AccumulationRegisters.VendorsARAPAccountingPlannedDeliveries.Synonym
			);
	Else
		Return 
			StrTemplate("
			|	%1
			|	%2
			|	%3
			|	%4",
			Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.Synonym,
			Metadata.AccumulationRegisters.CustomersARAPAccountingPlannedShipments.Synonym,
			Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.Synonym,
			Metadata.AccumulationRegisters.VendorsARAPAccountingPlannedDeliveries.Synonym
			);
	EndIf;
EndFunction

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
