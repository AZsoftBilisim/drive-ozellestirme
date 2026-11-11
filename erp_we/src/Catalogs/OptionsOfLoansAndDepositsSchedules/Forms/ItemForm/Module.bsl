
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	CopyLink = Parameters.CopyingValue;
	If Not CopyLink.IsEmpty() Then
		ReadGraphSet("TrancheSchedule", CopyLink);
		ReadGraphSet("PaymentSchedule", CopyLink);
		ReadGraphSet("ScheduleOfAccruals", CopyLink);
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ReadGraphSet("TrancheSchedule", CurrentObject.Ref);
	ReadGraphSet("PaymentSchedule", CurrentObject.Ref);
	ReadGraphSet("ScheduleOfAccruals", CurrentObject.Ref);
	
	UpdateRelatedData();
	
	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	LimitAmount = Common.ObjectAttributeValue(Object.Owner, "LimitAmount");
	
	If ValueIsFilled(LimitAmount) Then
		Set = GraphSet("TrancheSchedule", Object.Ref);
		TrancheAmount = Set.Total("Sum");
		
		If TrancheAmount > LimitAmount Then
			CommonClientServer.MessageToUser(
				StrTemplate(NStr("vi = 'Số tiền của các đợt thanh toán vượt quá giới hạn đã đặt trong hợp đồng %1 %2!';
								|ru = 'Сумма траншей превосходит заданный лимит в %1 %2 по договору!';
								|en = 'Total amount of tranches exceeds the limit specified in the contract (%1 %2).'; fa = 'Total amount of tranches exceeds the limit specified in the contract (%1 %2).';
								|it = 'L''importo delle tranche supera il limite specificato %1 %2 nel contratto!';
								|pl = 'Ilość transzy przekracza określony limit %1 %2 w umowie!';
								|tr = 'Dilim miktarı, sözleşme kapsamında belirtilen %1 %2 sınırını aşıyor!'"), LimitAmount, ContractCurrency),
				,,, Cancel);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.ChangeAuthor = UsersClientServer.CurrentUser();
	CurrentObject.ChangeDate = CurrentSessionDate();
	
	CurrentObject.TrancheAmount = TrancheSchedule.Total("Sum");
	CurrentObject.InterestAmount = PaymentSchedule.Total("Interests");
	CurrentObject.FeeAmount = PaymentSchedule.Total("Fee");
	
	CurrentObject.DateOfFirstTranche = DateOfFirstTranche;
	CurrentObject.LastPayment = LastPayment;
	
	Catalogs.OptionsOfLoansAndDepositsSchedules.RecalculateTerms(CurrentObject, "DateOfFirstTranche");
	
	CurrentObject.AdditionalProperties.Insert("RecordingGraphs", True);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CurrentObject.IsNew() Then
		LinkToCatalog = Catalogs.OptionsOfLoansAndDepositsSchedules.GetRef();
		CurrentObject.SetNewObjectRef(LinkToCatalog);
	Else
		LinkToCatalog = CurrentObject.Ref;
	EndIf;
	
	WriteSetOfGraph("TrancheSchedule", LinkToCatalog);
	WriteSetOfGraph("PaymentSchedule", LinkToCatalog);
	WriteSetOfGraph("ScheduleOfAccruals", LinkToCatalog);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ReadGraphSet("TrancheSchedule", CurrentObject.Ref);
	ReadGraphSet("PaymentSchedule", CurrentObject.Ref);
	ReadGraphSet("ScheduleOfAccruals", CurrentObject.Ref);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Record_VariantOfCreditAndDepositSchedules", WriteParameters, ThisForm);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	UpdatePaymentTotals();
	UpdateAccrualTotals();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerOnChange(Item)
	
	ConfigureFormByAgreement();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure ChartTableBeforeFinishingEditing(Item, NewRow, CancelEdit, Cancel)
	
	SpecifiedAmount = Item.CurrentData.Interests + Item.CurrentData.Fee;
	
	If Item.Name = "Payments" Then
		SpecifiedAmount = SpecifiedAmount + Item.CurrentData.Sum;
	EndIf;
	
	If SpecifiedAmount = 0 And (Not NewRow Or Not CancelEdit) Then
		Text = NStr("vi = 'Trong dòng cần chỉ ra ít nhất một trong các số tiền!';
					|ru = 'В строке должна быть указана хотя бы одна из сумм!';
					|en = 'The line must contain at least one of the amounts.'; fa = 'The line must contain at least one of the amounts.';
					|it = 'Nella riga deve essere indicato almeno uno degli importi!';
					|pl = 'W wierszu musi być określona chociaż jedna z kwot!';
					|tr = 'Satırda, tutarlardan en az biri belirtilmelidir!'");
		If Not NewRow And CancelEdit Then
			Text = NStr("vi = 'Không thể ghi lại các dòng có tổng bằng 0!
			|Xóa toàn bộ dòng.';
			|ru = 'Строки с нулевыми суммами не могут быть записаны!
			|Удалите всю строку целиком.';
			|en = 'Lines with zero amounts cannot be saved.
			|Delete the entire line.'; fa = 'Lines with zero amounts cannot be saved.
			|Delete the entire line.';
			|it = 'Non è possibile scrivere stringhe a somma zero! 
			| Eliminare l''intera stringa.';
			|pl = 'Wiersze z zerowymi wartościami nie można zapisać! 
			|Usuń cały wiersz w całości.';
			|tr = 'Sıfır tutarlı satırlar kaydedilemez!
			|Tüm satırı sil.'");
		EndIf;
		ShowMessageBox(, Text);
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure TranchesOnEditEnd(Item, NewRow, CancelEdit)
	
	Object.TrancheAmount = TrancheSchedule.Total("Sum");
	UpdateDates_();
	
EndProcedure

&AtClient
Procedure TranchesAfterDeleteRow(Item)
	
	Object.TrancheAmount = TrancheSchedule.Total("Sum");
	UpdateDates_();
	
EndProcedure

&AtClient
Procedure PaymentsAfterDeleteRow(Item)
	
	UpdatePaymentTotals();
	
EndProcedure

&AtClient
Procedure PaymentsOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdatePaymentTotals();
	
EndProcedure

&AtClient
Procedure AccrualsAfterDeleteRow(Item)
	
	UpdateAccrualTotals();
	
EndProcedure

&AtClient
Procedure AccrualsOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdateAccrualTotals();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	WriteSchedule(True);
	
EndProcedure

&AtClient
Procedure WriteScheduleOption(Command)
	
	WriteSchedule();
	
EndProcedure

&AtClient
Procedure DownloadScheduleOfTrenches(Command)
	
	ImportChart("TrancheSchedule");
	
EndProcedure

&AtClient
Procedure UploadPaymentSchedule(Command)
	
	ImportChart("PaymentSchedule");
	
EndProcedure

&AtClient
Procedure UploadAccrualSchedule(Command)
	
	ImportChart("ScheduleOfAccruals");
	
EndProcedure

&AtClient
Procedure ImportChart(ScheduleType)
	
	If ValueIsFilled(Object.Ref) Then
		UploadGraphSnippet(ScheduleType);
	Else
		ShowQueryBox(New CallbackDescription("LoadGraphAfterQuestion", ThisObject, New Structure("ScheduleType", ScheduleType)),
			NStr("vi = 'Cần ghi lại đối tượng trước khi tải.
				|Ghi lại và tiếp tục?';
				|ru = 'Перед загрузкой необходимо записать объект.
				|Записать и продолжить?';
				|en = 'You need to save the object before importing.
				|Do you want to save and continue?'; fa = 'You need to save the object before importing.
				|Do you want to save and continue?';
				|it = 'Prima di scaricare, è necessario registrare un oggetto. 
				| Registrare e continuare?';
				|pl = 'Przed pobraniem należy zapisać obiekt.
				|Zapisać i kontynuować?';
				|tr = 'Yüklenmeden önce nesne kaydedilmelidir.
				|Kaydedilip devam edilsin mi?'"),
			QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadGraphAfterQuestion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Write();
		UploadGraphSnippet(AdditionalParameters.ScheduleType);
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadGraphSnippet(Val ScheduleType)
	
	FormParameters = New Structure;
	FormParameters.Insert("ScheduleOption", Object.Ref);
	FormParameters.Insert("ScheduleType", ScheduleType);
	FormParameters.Insert("OwnerID", UUID);
	
	OpenForm("Catalog.OptionsOfLoansAndDepositsSchedules.Form.LoadForm",
		FormParameters,,,,,
		New CallbackDescription("ImportChartCompletion", ThisObject, New Structure("ScheduleType", ScheduleType)),
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure ImportChartCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("String") And IsTempStorageURL(Result) Then
		ScheduleType = AdditionalParameters.ScheduleType;
		UploadCompletionScheduleToServer(ScheduleType, Result);
		If ScheduleType = "TrancheSchedule" Then
			Object.TrancheAmount = TrancheSchedule.Total("Sum");
			UpdateDates_();
		ElsIf ScheduleType = "PaymentSchedule" Then
			UpdatePaymentTotals();
		ElsIf ScheduleType = "ScheduleOfAccruals" Then
			UpdateAccrualTotals();
		EndIf;
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure UploadCompletionScheduleToServer(ScheduleType, AddressOfRecordset)
	
	RecordSet = Common.ValueFromXMLString(GetFromTempStorage(AddressOfRecordset));
	ValueToFormAttribute(RecordSet, ScheduleType);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

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

#EndRegion

#Region Private

Procedure OnReadCreateAtServer()
	
	ConfigureFormByAgreement();
	
EndProcedure

&AtClient
Procedure UpdateDates_()
	
	If TrancheSchedule.Count() > 0 Then
		TrancheSchedule.Sort("Period");
		DateOfFirstTranche = TrancheSchedule[0].Period;
	Else
		DateOfFirstTranche = Undefined;
	EndIf;
	
	If PaymentSchedule.Count() > 0 Then
		PaymentSchedule.Sort("Period");
		LastPayment = PaymentSchedule[PaymentSchedule.Count()-1].Period;
	Else
		LastPayment = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAccrualTotals()
	
	InterestAccruals = ScheduleOfAccruals.Total("Interests");
	CommissionAccruals = ScheduleOfAccruals.Total("Fee");
	ScheduleOfAccruals.Sort("Period");
	
EndProcedure

&AtClient
Procedure UpdatePaymentTotals()
	
	PayAmount = PaymentSchedule.Total("Sum");
	InterestAmount = PaymentSchedule.Total("Interests");
	FeeAmount = PaymentSchedule.Total("Fee");
	UpdateDates_();
	
EndProcedure

&AtServer
Procedure ConfigureFormByAgreement()
	
	ContractDetails_ = Common.ObjectAttributesValues(Object.Owner,
		"ARAPCurrency, ContractKind, Status, FeeType");
	
	ContractCurrency = ContractDetails_.ARAPCurrency;
	RowCurrency = String(ContractCurrency);
	ContractKind = ContractDetails_.ContractKind;
	
	Items.TranchesGroup.Title       = StrTemplate(NStr("vi = 'Tổng số đợt ( %1)';
														|ru = 'Всего транши (%1)';
														|en = 'Total tranches (%1)'; fa = 'Total tranches (%1)';
														|it = 'Totale tranche (%1)';
														|pl = 'Łącznie transz (%1)';
														|tr = 'Toplam dilim (%1)'"), RowCurrency);
	Items.PaymentGroup.Title       = StrTemplate(NStr("vi = 'Tổng số thanh toán (%1)';
														|ru = 'Всего оплата (%1)';
														|en = 'Total payment (%1)'; fa = 'Total payment (%1)';
														|it = 'Totale pagamento (%1)';
														|pl = 'Łącznie płatność (%1)';
														|tr = 'Toplam ödeme (%1)'"), RowCurrency);
	Items.AccrualGroup.Title   = StrTemplate(NStr("vi = 'Tổng số lãi vay (%1)';
													|ru = 'Всего начисления (%1)';
													|en = 'Total accruals (%1)'; fa = 'Total accruals (%1)';
													|it = 'Totale maturazione (%1)';
													|pl = 'Łącznie naliczenia (%1)';
													|tr = 'Tahakkuk toplamı (%1)'"), RowCurrency);
	Items.TranchesSum.Title        = StrTemplate(NStr("vi = 'Số tiền (%1)';
														|ru = 'Сумма (%1)';
														|en = 'Amount (%1)'; fa = 'Amount (%1)';
														|it = 'Totale (%1)';
														|pl = 'Wartość (%1)';
														|tr = 'Tutar (%1)'"), RowCurrency);
	Items.PaymentsSum.Title        = StrTemplate(NStr("vi = 'Số tiền nợ gốc (%1)';
														|ru = 'Сумма основного долга (%1)';
														|en = 'Principal debt (%1)'; fa = 'Principal debt (%1)';
														|it = 'Importo debito principale (%1)';
														|pl = 'Wartość długu zasadniczego (%1)';
														|tr = 'Ana borç tutarı (%1)'"), RowCurrency);
	Items.PaymentsInterests.Title     = StrTemplate(NStr("vi = 'Lãi vay (%1)';
														|ru = 'Сумма процентов (%1)';
														|en = 'Interest amount (%1)'; fa = 'Interest amount (%1)';
														|it = 'Importo percentuali (%1)';
														|pl = 'Wartość procentów (%1)';
														|tr = 'Faiz tutarı (%1)'"), RowCurrency);
	Items.PaymentsFee.Title     = StrTemplate(NStr("vi = 'Phí ngân hàng (%1)';
													|ru = 'Сумма комиссии (%1)';
													|en = 'Fee amount (%1)'; fa = 'Fee amount (%1)';
													|it = 'Importo commissioni (%1)';
													|pl = 'Wartość prowizji (%1)';
													|tr = 'Komisyon tutarı (%1)'"), RowCurrency);
	Items.AccrualsInterests.Title = StrTemplate(NStr("vi = 'Lãi vay (%1)';
													|ru = 'Сумма процентов (%1)';
													|en = 'Interest amount (%1)'; fa = 'Interest amount (%1)';
													|it = 'Importo percentuali (%1)';
													|pl = 'Wartość procentów (%1)';
													|tr = 'Faiz tutarı (%1)'"), RowCurrency);
	Items.AccrualsFee.Title = StrTemplate(NStr("vi = 'Phí ngân hàng (%1)';
												|ru = 'Сумма комиссии (%1)';
												|en = 'Fee amount (%1)'; fa = 'Fee amount (%1)';
												|it = 'Importo commissioni (%1)';
												|pl = 'Wartość prowizji (%1)';
												|tr = 'Komisyon tutarı (%1)'"), RowCurrency);
	
	ThereIsACommission = (ContractDetails_.FeeType <> Enums.LoanAndDepositFeeTypes.None);
	ItemArray = New Array;
	ItemArray.Add("PaymentsFee");
	ItemArray.Add("FeeAmount");
	ItemArray.Add("AccrualsFee");
	ItemArray.Add("AccrualsTotalCommission");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", ThereIsACommission);
	
	ContractIsClosed = (ContractDetails_.Status = Enums.CounterpartyContractStatuses.Closed);
	Items.TheInscriptionTheContractIsClosed.Visible = ContractIsClosed;
	ItemArray = New Array();
	ItemArray.Add("FormWrite");
	ItemArray.Add("FormWriteAndClose");
	ItemArray.Add("Used");
	ItemArray.Add("Upholded");
	ItemArray.Add("ContractDescription");
	ItemArray.Add("DescriptionCode");
	ItemArray.Add("TranchesCommandBar");
	ItemArray.Add("PaymentsCommandBar");
	ItemArray.Add("AccrualsCommandBar");
	ItemArray.Add("Comment");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", Not ContractIsClosed);
	
EndProcedure

&AtServer
Procedure ReadGraphSet(ScheduleType, Ref)
	
	Set = GraphSet(ScheduleType, Ref);
	Set.Read();
	ValueToFormAttribute(Set, ScheduleType);
	
EndProcedure

&AtServer
Procedure WriteSetOfGraph(ScheduleType, Ref)
	
	Set = GraphSet(ScheduleType, Ref);
	Set.Fill(New Structure("ScheduleOption", Ref));
	
	ArrayOfResources = New Array;
	RecruitmentResources = Set.Metadata().Resources;
	For Each SetResource In RecruitmentResources Do
		ArrayOfResources.Add(SetResource.Name);
	EndDo;
	
	SetData = Set.Unload();
	SetData.GroupBy("Period,ScheduleOption", StrConcat(ArrayOfResources, ","));
	Set.Load(SetData);
	
	Set.Write();
	
EndProcedure

&AtServer
Function GraphSet(ScheduleType, Ref)
	
	If ScheduleType = "ScheduleOfAccruals" Then
		RegisterName = Metadata.InformationRegisters.ScheduleOfAccrualsForLoansAndDeposits.Name;
	ElsIf ScheduleType = "PaymentSchedule" Then
		RegisterName = Metadata.InformationRegisters.ScheduleOfPaymentForLoansAndDeposits.Name;
	ElsIf ScheduleType = "TrancheSchedule" Then
		RegisterName = Metadata.InformationRegisters.ScheduleOfTrancheForLoansAndDeposits.Name;
	Else
		Raise StrTemplate(NStr("vi = 'Chưa xác định biểu ghi thông tin để lưu lại dữ liệu lịch biểu ""%1""';
								|ru = 'Не определен регистр сведений для хранения данных графика ""%1""';
								|en = 'No information register defined for storing scheduled ""%1"" data'; fa = 'No information register defined for storing scheduled ""%1"" data';
								|it = 'Registro informazioni per l''archiviazione dei dati del grafico ""%1"" non è definito';
								|pl = 'Nie określono rejestru danych do przechowywania danych harmonogramu ""%1""';
								|tr = 'Program verilerinin depolanması için bilgi kaydı tanımlanmadı ""%1""'"), ScheduleType);
	EndIf;
	
	Set = FormAttributeToValue(ScheduleType, Type("InformationRegisterRecordSet." + RegisterName)); // InformationRegisterRecordSet
	Set.Filter.ScheduleOption.Set(Ref);
	
	Return Set;
	
EndFunction

&AtClient
Function SumsOfGraphsConverge()
	
	DebtAmountsAreEqual = (Object.TrancheAmount = PayAmount);
	PercentagesAreEqual   = (InterestAmount = InterestAccruals);
	CommissionIsEqualTo   = (FeeAmount = CommissionAccruals);
	
	If Not DebtAmountsAreEqual Then
		ClearMessages();
		Text  = NStr("vi = 'Tổng số tiền nợ gốc trên các trang ""Chuyển"" và ""Thanh toán"" khác nhau.';
					|ru = 'Различаются итоговые суммы основного долга на закладках ""Транши"" и ""Оплаты"".';
					|en = 'Total principal debt amounts specified on the Tranches and Payments tabs do not match.'; fa = 'Total principal debt amounts specified on the Tranches and Payments tabs do not match.';
					|it = 'Gli importi totali del debito principale sono diversi nelle schede ""Tranche"" e ""Pagamenti"".';
					|pl = 'Różnią się wartości wynikowe długu zasadniczego na kartach ""Транши"" i ""Оплаты"".';
					|tr = 'Anapara borcunun toplam tutarları ""Dilimler"" ve ""Ödemeler"" sekmelerinde farklılık gösterir.'");
		CommonClientServer.MessageToUser(Text);
	EndIf;
	
	If Not PercentagesAreEqual Then
		ClearMessages();
		Text  = NStr("vi = 'Tổng số tiền lãi trên các trang ""Thanh toán"" và ""Trích"" khác nhau.';
					|ru = 'Различаются итоговые суммы процентов на закладках ""Оплаты"" и ""Начисления"".';
					|en = 'Total interest amounts specified on the Payments and Accruals tabs do not match.'; fa = 'Total interest amounts specified on the Payments and Accruals tabs do not match.';
					|it = 'Gli importi totali dellle percentuali sono diversi nelle schede ""Pagamenti"" e ""Maturazioni"".';
					|pl = 'Różnią się wartości wynikowe procentów na kartach ""Оплаты"" i ""Начисления"".';
					|tr = '""Ödemeler"" ve ""Tahakkuklar"" sekmelerindeki toplam faiz tutarları farklıdır.'");
		CommonClientServer.MessageToUser(Text);
	EndIf;
	
	If ThereIsACommission And Not CommissionIsEqualTo Then
		ClearMessages();
		Text  = NStr("vi = 'Tổng số tiền phí trên các trang ""Thanh toán"" và ""Trích"" khác nhau.';
					|ru = 'Различаются итоговые суммы комиссии на закладках ""Оплаты"" и ""Начисления"".';
					|en = 'Total fee amounts specified on the Payments and Accruals tabs do not match.'; fa = 'Total fee amounts specified on the Payments and Accruals tabs do not match.';
					|it = 'Gli importi totali delle commissioni sono diversi nelle schede ""Pagamenti"" e ""Maturazioni"".';
					|pl = 'Różnią się wartości wynikowe prowizji na kartach ""Оплаты"" i ""Начисления"".';
					|tr = 'Toplam komisyon tutarları ""Ödemeler"" ve ""Tahakkuklar"" sekmelerinde farklılık gösterir.'");
		CommonClientServer.MessageToUser(Text);
	EndIf;
	
	Return DebtAmountsAreEqual And PercentagesAreEqual And (CommissionIsEqualTo Or Not ThereIsACommission);
	
EndFunction

&AtServer
Procedure UpdateRelatedData()
	
	ScheduleData = Catalogs.OptionsOfLoansAndDepositsSchedules.GraphResults(Object.Ref);
	FillPropertyValues(ThisForm, ScheduleData, "PayAmount, InterestAccruals, CommissionAccruals");
	
EndProcedure

&AtClient
Procedure WriteSchedule(CloseAfterRecording = False)
	
	If Not SumsOfGraphsConverge() Then
		ShowQueryBox(New CallbackDescription("ProcessingResponseToIgnoreQuestion", ThisObject, CloseAfterRecording),
			NStr("vi = 'Trong phiên bản hiện tại của biểu đồ, các tổng số khác nhau.
			|Bỏ qua?';
			|ru = 'В текущем варианте графика различаются итоговые суммы.
			|Игнорировать?';
			|en = 'Total amounts specified in the current schedule option do not match.
			|Ignore?'; fa = 'Total amounts specified in the current schedule option do not match.
			|Ignore?';
			|it = 'Nella versione corrente della pianificazione, i totali differiscono.
			| Ignora?';
			|pl = 'W bieżącym wariancie harmonogramu różnią się wartości wynikowe. 
			|Ignorować?';
			|tr = 'Programın mevcut seçeneğinde toplam tutarlar farklılık gösterir.
			|Görmezden gel?'"),
			QuestionDialogMode.YesNo);
	Else
		ExecuteWriteObject(CloseAfterRecording);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingResponseToIgnoreQuestion(Response, CloseAfterRecording) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ExecuteWriteObject(CloseAfterRecording);
	
EndProcedure

&AtClient
Procedure ExecuteWriteObject(CloseAfterRecording = False)
	
	Write();
	If CloseAfterRecording Then
		Close();
	EndIf;
	
EndProcedure

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
