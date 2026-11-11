
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	SetColumnHeaders();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure


&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(TransactionsWithCorrespondence, "Dr");
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(TransactionsWithCorrespondence, "Cr");
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(TransactionsWithoutCorrespondence, "");
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	CurrentObject.TransactionsWithCorrespondence.Load(TransactionsWithCorrespondence.Unload());
	
	CurrentObject.TransactionsWithoutCorrespondence.Clear();
	For Each Record In TransactionsWithoutCorrespondence Do
		NewRow = CurrentObject.TransactionsWithoutCorrespondence.Add();
		FillPropertyValues(NewRow, Record);
		If Record.RecordType = TypeOfMovementDebit Then
			NewRow.RecordType = Enums.AccountingMovementKinds.Debit;
		ElsIf Record.RecordType = TypeOfMovementCredit Then
			NewRow.RecordType = Enums.AccountingMovementKinds.Credit;
		Else
			NewRow.RecordType = Enums.AccountingMovementKinds.EmptyRef();
		EndIf;
	EndDo;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	UpdateDisplayAccordingToChartOfAccounts();
EndProcedure

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	
	ThereAreRegisteredRecords = 
		TransactionsWithoutCorrespondence.Count() > 0
		Or TransactionsWithCorrespondence.Count() > 0;
		
	If ThereAreRegisteredRecords And CurrentAccountPlan <> Object.ChartOfAccounts Then
		CallbackDescription = New CallbackDescription("WhenChangingChartOfAccountsQuestion", ThisObject);
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Kontynuuj';
												|tr = 'Devam'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"));
		ShowQueryBox(CallbackDescription, NStr("vi = 'Sẽ xóa mẫu bút toán. Tiếp tục?';
												|ru = 'Шаблон проводок будет очищен. Продолжить?';
												|en = 'Posting template will be cleared. Continue?'; fa = 'Posting template will be cleared. Continue?';
												|it = 'Il modello delle transazioni sarà cancellato. Continuare?';
												|pl = 'Szablon wpisów księgowych zostanie wyczyszczone. Kontynuować?';
												|tr = 'Kayıt şablonu temizlenecektir. Devam edilsin mi?'"), Buttons);
	Else
		CurrentAccountPlan = Object.ChartOfAccounts;
		UpdateDisplayAccordingToChartOfAccounts();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransactionsWithCorrespondence

&AtClient
Procedure TransactionsWithCorrespondenceBeforeRowChange(Item, Cancel)
	TableRow = Items.TransactionsWithCorrespondence.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Dr");
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Cr");
EndProcedure

&AtClient
Procedure AccountDrOnChange(Item)
	CurrentData = Items.TransactionsWithCorrespondence.CurrentData;
	FillPropertyValues(CurrentData, PresentationOfExtdimensionAccounts(CurrentData.AccountDr, "Dr"));
EndProcedure

&AtClient
Procedure AccountCrOnChange(Item)
	CurrentData = Items.TransactionsWithCorrespondence.CurrentData;
	FillPropertyValues(CurrentData, PresentationOfExtdimensionAccounts(CurrentData.AccountCr, "Cr"));
EndProcedure

&AtClient
Procedure SumOnChange(Item)
	CurrentRow = Items.TransactionsWithCorrespondence.CurrentData;
	CurrentRow.PresentationAmount = CalculateSumOfPresentation(Object.ChartOfAccounts, Object.Organization, CurrentRow.Sum);
EndProcedure

&AtClient
Procedure DrSExtDimensionWhenChanging(Item)
	TableRow = Items.TransactionsWithCorrespondence.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Dr");
EndProcedure

&AtClient
Procedure DrSSubContactExtDimensionIsProcessingOfSelection(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimensionOfCrWhenChanging(Item)
	TableRow = Items.TransactionsWithCorrespondence.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Cr");
EndProcedure

&AtClient
Procedure CrSSubContactExtDimensionIsProcessingOfSelection(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransactionsWithoutCorrespondence

&AtClient
Procedure TransactionsWithoutCorrespondenceOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.TransactionsWithoutCorrespondence.CurrentData;
	If NewRow And Not Copy Then
		CurrentRow.Active = False;
		If TotalAmount_5Dr >= TotalAmount_5Cr Then
			CurrentRow.RecordType = TypeOfMovementCredit;
			CurrentRow.SumCr = TotalAmount_5Dr - TotalAmount_5Cr;
			CurrentRow.Sum = CurrentRow.SumCr;
			
			CurrentRow.PresentationAmountCr = CalculateSumOfPresentation(Object.ChartOfAccounts, Object.Organization, CurrentRow.Sum);
			CurrentRow.PresentationAmount = CurrentRow.PresentationAmountCr;
		Else
			CurrentRow.RecordType = TypeOfMovementDebit;
			CurrentRow.SumDr = TotalAmount_5Cr - TotalAmount_5Dr;
			CurrentRow.Sum = CurrentRow.SumDr;
			
			CurrentRow.PresentationAmountDr = CalculateSumOfPresentation(Object.ChartOfAccounts, Object.Organization, CurrentRow.Sum);
			CurrentRow.PresentationAmount = CurrentRow.PresentationAmountDr;
		EndIf;
		CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
		CurrentRow.TypeOfMovementIndex = 
			TypeOfMovementWithoutCorrelationIndexOfImage(CurrentRow.RecordType, CurrentRow.Active, CurrentRow.Sum, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure TransactionsWithoutCorrespondenceBeforeRowChange(Item, Cancel)
	TableRow = Items.TransactionsWithoutCorrespondence.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "");
EndProcedure

&AtClient
Procedure TransactionsWithoutCorrespondenceOnEditEnd(Item, NewRow, CancelEdit)
	If Not CancelEdit Then
		CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure TransactionsWithoutCorrespondenceAfterDeleteRow(Item)
	CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
EndProcedure

&AtClient
Procedure AccountOnChange(Item)
	CurrentData = Items.TransactionsWithoutCorrespondence.CurrentData;
	FillPropertyValues(CurrentData, PresentationOfExtdimensionAccounts(CurrentData.Account, ""));
EndProcedure

&AtClient
Procedure SumDrOnChange(Item)
	
	CurrentData = Items.TransactionsWithoutCorrespondence.CurrentData;
	CurrentData.RecordType = TypeOfMovementDebit;
	CurrentData.Sum = CurrentData.SumDr;
	CurrentData.SumCr = 0;
	
	CurrentData.PresentationAmountDr = CalculateSumOfPresentation(Object.ChartOfAccounts, Object.Organization, CurrentData.Sum);
	CurrentData.PresentationAmount = CurrentData.PresentationAmountDr;
	CurrentData.PresentationAmountCr = 0;
	
	CurrentData.TypeOfMovementIndex = 
		TypeOfMovementWithoutCorrelationIndexOfImage(CurrentData.RecordType, CurrentData.Active, CurrentData.Sum, ThisObject);
	
EndProcedure

&AtClient
Procedure SumCrOnChange(Item)
	
	CurrentData = Items.TransactionsWithoutCorrespondence.CurrentData;
	CurrentData.RecordType = TypeOfMovementCredit;
	CurrentData.Sum = CurrentData.SumCr;
	CurrentData.SumDr = 0;
	
	CurrentData.PresentationAmountCr = CalculateSumOfPresentation(Object.ChartOfAccounts, Object.Organization, CurrentData.Sum);
	CurrentData.PresentationAmount = CurrentData.PresentationAmountCr;
	CurrentData.PresentationAmountDr = 0;
	
	CurrentData.TypeOfMovementIndex = 
		TypeOfMovementWithoutCorrelationIndexOfImage(CurrentData.RecordType, CurrentData.Active, CurrentData.Sum, ThisObject);
		
EndProcedure

&AtClient
Procedure PresentationAmountDrOnChange(Item)
	CurrentData = Items.TransactionsWithoutCorrespondence.CurrentData;
	CurrentData.PresentationAmount = CurrentData.PresentationAmountDr;
	CurrentData.RecordType = TypeOfMovementDebit;
	If CurrentData.SumCr <> 0 Then
		CurrentData.SumCr = 0;
		CurrentData.Sum = 0;
	EndIf;
	If CurrentData.PresentationAmountCr <> 0 Then
		CurrentData.PresentationAmountCr = 0;
	EndIf;
EndProcedure

&AtClient
Procedure PresentationAmountCrOnChange(Item)
	CurrentData = Items.TransactionsWithoutCorrespondence.CurrentData;
	CurrentData.PresentationAmount = CurrentData.PresentationAmountCr;
	CurrentData.RecordType = TypeOfMovementCredit;
	If CurrentData.SumDr <> 0 Then
		CurrentData.SumDr = 0;
		CurrentData.Sum = 0;
	EndIf;
	If CurrentData.PresentationAmountDr <> 0 Then
		CurrentData.PresentationAmountDr = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyAmountOnChange(Item)
	CurrencyOnChangeClient(Items.TransactionsWithoutCorrespondence, "");
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	CurrencyOnChangeClient(Items.TransactionsWithoutCorrespondence, "");
EndProcedure

&AtClient
Procedure ExtDimensionWhenChanging(Item)
	TableRow = Items.TransactionsWithoutCorrespondence.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "");
EndProcedure

&AtClient
Procedure ExtDimensionOfSelectionProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// registration of the fields "Subconto1", ... etc.
	FinancialAccountingOfGeneralPurpose.SetTransactionLayout(ConditionalAppearance, "TransactionsWithCorrespondence");
	FinancialAccountingOfGeneralPurpose.SetTransactionLayout(ConditionalAppearance, "TransactionsWithoutCorrespondence", False);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	TypeOfMovementDebit = AccountingRecordType.Debit;
	TypeOfMovementCredit = AccountingRecordType.Credit;
	OverdueDataColor = StyleColors.OverdueDataColor;
	CurrentAccountPlan = Object.ChartOfAccounts;
	
	TransactionsWithCorrespondence.Load(Object.TransactionsWithCorrespondence.Unload());
	
	For Each Record In Object.TransactionsWithoutCorrespondence Do
		NewRow = TransactionsWithoutCorrespondence.Add();
		FillPropertyValues(NewRow, Record);
		If Record.RecordType = Enums.AccountingMovementKinds.Debit Then
			NewRow.RecordType = TypeOfMovementDebit;
		ElsIf Record.RecordType = Enums.AccountingMovementKinds.Credit Then
			NewRow.RecordType = TypeOfMovementCredit;
		Else
			NewRow.RecordType = Undefined;
		EndIf;
	EndDo;
	
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(TransactionsWithCorrespondence, "Dr");
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(TransactionsWithCorrespondence, "Cr");
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(TransactionsWithoutCorrespondence, "");
	FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence();
	UpdateDisplayAccordingToChartOfAccounts();
	
EndProcedure

&AtServer
Procedure SetColumnHeaders()

	CurrencyInt = FinancialAccountingOfGeneralPurpose.AccountingCurrencies(Object.ChartOfAccounts, Object.Organization);
	
	Template = NStr("vi = 'Tổng số';
					|ru = 'Сумма';
					|en = 'Amount'; fa = 'مبلغ';
					|it = 'Importo';
					|pl = 'Wartość';
					|tr = 'Tutar'") + " (%1)";
	Text = StringFunctionsClientServer.SubstituteParametersToString(Template, String(CurrencyInt.Functional));
	Items.Sum.Title = Text;
	
	Template = NStr("vi = 'Số tiền nộp';
					|ru = 'Сумма представления';
					|en = 'Presentation amount'; fa = 'مبلغ گزارشگری';
					|it = 'Importo di visualizzazione';
					|pl = 'Dział Wn';
					|tr = 'Tutar (sunum para birimi)'") + " (%1)";
	Text = StringFunctionsClientServer.SubstituteParametersToString(Template, String(CurrencyInt.Presentations));
	Items.PresentationAmount.Title = Text;
	TitleTemplate1 = NStr("vi = 'Bộ phận %1';
							|ru = 'Подразделение %1';
							|en = 'Business unit %1'; fa = 'Business unit %1';
							|it = 'Reparto %1';
							|pl = 'Komórka %1';
							|tr = 'Departman: %1'");
	If Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed() Then
		TitleTemplate1 = TitleTemplate1 + ", " + NStr("vi = 'Hướng %1';
														|ru = 'Направление %1';
														|en = 'Line of business %1'; fa = 'Line of business %1';
														|it = 'Direzione %1';
														|pl = 'Kierunek %1';
														|tr = 'Yön %1'")
	EndIf;
	Items.DepartmentDr.Title = StrTemplate(TitleTemplate1, NStr("vi = 'Nợ';
																|ru = 'Дт';
																|en = 'Dr'; fa = 'بد';
																|it = 'Debito';
																|pl = 'Wn';
																|tr = 'Borç'"));
	Items.DepartmentCr.Title = StrTemplate(TitleTemplate1, NStr("vi = 'Có';
																|ru = 'Кт';
																|en = 'Cr'; fa = 'بس';
																|it = 'Credito';
																|pl = 'Ma';
																|tr = 'Alacak'"));
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Function PresentationOfExtdimensionAccounts(Account, DrCr)
	
	Return FinancialAccountingOfGeneralPurpose.PresentationOfExtdimensionSpecies(Account, DrCr);
	
EndFunction

&AtServerNoContext
Function CalculateSumOfPresentation(ChartOfAccounts, Organization, Sum)
	
	Return FinancialAccountingOfGeneralPurpose.CalculateSumOfPresentation(ChartOfAccounts, Organization, Sum);
	
EndFunction

&AtClient
Procedure CurrencyOnChangeClient(FormTable, DrCr)
	
	CurrentRow = FormTable.CurrentData;
	TransactionAmounts = CalculateAmounts(Object.ChartOfAccounts, Object.Organization, CurrentRow["CurrencyAmount"+DrCr], CurrentRow["Currency"+DrCr]);
	FillPropertyValues(CurrentRow, TransactionAmounts);
	
EndProcedure

&AtServerNoContext
Function CalculateAmounts(ChartOfAccounts, Organization, CurrencyAmount, Currency)
	
	TransactionAmounts = New Structure("Sum,PresentationAmount",0,0);
	ConversionFactor = FinancialAccountingOfGeneralPurpose.GetCurrencyConversionRates_(ChartOfAccounts, Organization, Currency, CurrentSessionDate());
	TransactionAmounts.Sum = CurrencyAmount * ConversionFactor.ToFunctionalCurrency;
	TransactionAmounts.PresentationAmount = CurrencyAmount * ConversionFactor.CurrencyOfPresentation;
	
	Return TransactionAmounts;
	
EndFunction

&AtClient
Procedure ClearSelectionOptions(Item)
	Item.ChoiceParameters = New FixedArray(New Array);
EndProcedure

&AtClient
Procedure WhenChangingChartOfAccountsQuestion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		TransactionsWithoutCorrespondence.Clear();
		TransactionsWithCorrespondence.Clear();
		CurrentAccountPlan = Object.ChartOfAccounts;
		UpdateDisplayAccordingToChartOfAccounts();
	Else
		Object.ChartOfAccounts = CurrentAccountPlan;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDisplayAccordingToChartOfAccounts()
	
	CurrencyInt = FinancialAccountingOfGeneralPurpose.AccountingCurrencies(Object.ChartOfAccounts, Object.Organization);
	
	If Not ValueIsFilled(CurrencyInt.Functional) Then
		TextAmount = NStr("vi = 'Chức năng';
							|ru = 'Функц.';
							|en = 'Functional'; fa = 'Functional';
							|it = 'Funz.';
							|pl = 'Funkc.';
							|tr = 'Fonksiyonel'");
		TextAmountDr = NStr("vi = 'Số tiền chức năng Nợ';
							|ru = 'Сумма функц. Дт';
							|en = 'Dr funct. currency amount'; fa = 'Dr funct. currency amount';
							|it = 'Importo funz. Db';
							|pl = 'Wartość funkc. Wn';
							|tr = 'Tutar (fonks. para birimi) Borç'");
		TextAmountCr = NStr("vi = 'Số tiền chức năng Có';
							|ru = 'Сумма функц. Кт';
							|en = 'Cr funct. currency amount'; fa = 'Cr funct. currency amount';
							|it = 'Importo funz. Cd';
							|pl = 'Wartość funkc. Ma';
							|tr = 'Tutar (fonks. para birimi) Alacak'");
	Else
		TextAmount = StrTemplate(NStr("vi = 'Chức năng (%1)';
										|ru = 'Функц. (%1)';
										|en = 'Funct. (%1)'; fa = 'Funct. (%1)';
										|it = 'Funzionale (%1)';
										|pl = 'Funkc. (%1)';
										|tr = 'Fonks. (%1)'"), String(CurrencyInt.Functional));
		TextAmountDr = StrTemplate(NStr("vi = 'Số tiền chức năng Nợ (%1)';
										|ru = 'Сумма функц. Дт (%1)';
										|en = 'Funct. currency amount Dr (%1)'; fa = 'Funct. currency amount Dr (%1)';
										|it = 'Importo funz. Db (%1)';
										|pl = 'Wartość funkc. Wn (%1)';
										|tr = 'Tutar (fonks. para birimi) Borç (%1)'"), String(CurrencyInt.Functional));
		TextAmountCr = StrTemplate(NStr("vi = 'Số tiền chức năng Có (%1)';
										|ru = 'Сумма функц. Кт (%1)';
										|en = 'Cr funct. currency amount (%1)'; fa = 'Cr funct. currency amount (%1)';
										|it = 'Importo funz. Cd (%1)';
										|pl = 'Wartość funkc. Ma (%1)';
										|tr = 'Tutar (fonks. para birimi) Alacak (%1)'"), String(CurrencyInt.Functional));
	EndIf;
	Items.Sum.Title = TextAmount;
	Items.SumDr.Title = TextAmountDr;
	Items.SumCr.Title = TextAmountCr;
	
	Items.PresentationAmount.Visible = True;
	Items.PresentationAmountDr.Visible = True;
	Items.PresentationAmountCr.Visible = True;
	If Not ValueIsFilled(CurrencyInt.Presentations) Then
		TextSumOfView = NStr("vi = 'Trước đó';
							|ru = 'Пред.';
							|en = 'Presentation'; fa = 'نمایش';
							|it = 'Prec.';
							|pl = 'Prez.';
							|tr = 'Geçmiş'");
		TextSumOfViewDr = NStr("vi = 'Số tiền trình bày Nợ';
								|ru = 'Сумма предст. Дт';
								|en = 'Dr present. amount'; fa = 'مبلغ نمایش بدهکار';
								|it = 'Importo pres. Db';
								|pl = 'Wartość prez. Wn';
								|tr = 'Tutar sunum para birimi Borç'");
		TextSumOfViewCr = NStr("vi = 'Số tiền trình bày Có';
								|ru = 'Сумма предст. Кт';
								|en = 'Cr present. amount'; fa = 'مبلغ نمایش بستانکار';
								|it = 'Importo pres. Cd';
								|pl = 'Wartość prez. Ma';
								|tr = 'Tutar sunum para birimi Alacak'");
	Else
		TextSumOfView = StrTemplate(NStr("vi = 'Trước đó (%1)';
										|ru = 'Пред. (%1)';
										|en = 'Present. (%1)'; fa = 'Present. (%1)';
										|it = 'Visualizzazione (%1)';
										|pl = 'Prez. (%1)';
										|tr = 'Geçmiş (%1)'"), String(CurrencyInt.Presentations));
		TextSumOfViewDr = StrTemplate(NStr("vi = 'Số tiền trình bày Nợ (%1)';
											|ru = 'Сумма предст. Дт (%1)';
											|en = 'Dr present. amount (%1)'; fa = 'Dr present. amount (%1)';
											|it = 'Importo pres. Db (%1)';
											|pl = 'Wartość prez. Wn (%1)';
											|tr = 'Tutar sunum para birimi Borç (%1)'"), String(CurrencyInt.Presentations));
		TextSumOfViewCr = StrTemplate(NStr("vi = 'Số tiền trình bày Có (%1)';
											|ru = 'Сумма предст. Кт (%1)';
											|en = 'Cr present. amount (%1)'; fa = 'Cr present. amount (%1)';
											|it = 'Importo pres. Cd (%1)';
											|pl = 'Wartość prez. Ma (%1)';
											|tr = 'Tutar sunum para birimi Alacak (%1)'"), String(CurrencyInt.Presentations));
	EndIf;
	Items.PresentationAmount.Title = TextSumOfView;
	Items.PresentationAmountDr.Title = TextSumOfViewDr;
	Items.PresentationAmountCr.Title = TextSumOfViewCr;
	
	If ValueIsFilled(CurrencyInt.Functional) And CurrencyInt.Functional = CurrencyInt.Presentations Then
		Items.PresentationAmount.Visible = False;
		Items.PresentationAmountDr.Visible = False;
		Items.PresentationAmountCr.Visible = False;
		TextAmount = StrTemplate(NStr("vi = 'Số tiền (%1)';
										|ru = 'Сумма (%1)';
										|en = 'Amount (%1)'; fa = 'Amount (%1)';
										|it = 'Importo (%1)';
										|pl = 'Wartość (%1)';
										|tr = 'Tutar (%1)'"), String(CurrencyInt.Functional));
		TextAmountDr = StrTemplate(NStr("vi = 'Số tiền Nợ (%1)';
										|ru = 'Сумма Дт (%1)';
										|en = 'Dr amount (%1)'; fa = 'Dr amount (%1)';
										|it = 'Importo Db (%1)';
										|pl = 'Wartość Wn (%1)';
										|tr = 'Tutar Borç (%1)'"), String(CurrencyInt.Functional));
		TextAmountCr = StrTemplate(NStr("vi = 'Số tiền Có (%1)';
										|ru = 'Сумма Кт (%1)';
										|en = 'Cr amount (%1)'; fa = 'Cr amount (%1)';
										|it = 'Importo Cd (%1)';
										|pl = 'Wartość Ma (%1)';
										|tr = 'Tutar Alacak (%1)'"), String(CurrencyInt.Functional));
		Items.Sum.Title = TextAmount;
		Items.SumDr.Title = TextAmountDr;
		Items.SumCr.Title = TextAmountCr;
	EndIf;
	
	OptionForGeneratingTransactions = Common.ObjectAttributeValue(Object.ChartOfAccounts, "OptionForGeneratingTransactions");
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
		Items.TransactionTemplatePages.CurrentPage = Items.PageIsTemplateForTransactionsWithoutCorrespondence;
	ElsIf OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		Items.TransactionTemplatePages.CurrentPage = Items.PageIsTemplateForTransactionsWithCorrespondence;
	Else
		Items.TransactionTemplatePages.CurrentPage = Items.SelectChartOfAccountsPage;
	EndIf;
	
	AddTypesOfInvalidTransactions();
	
EndProcedure

&AtServer
Procedure AddTypesOfInvalidTransactions()
	
	If ValueIsFilled(Object.Organization) Then
		PostingGenerationSetting = FinancialAccountingServerCached.UsedSettingsForGeneratingTransactions(
			BegOfMonth(CurrentSessionDate()), Object.ChartOfAccounts, Object.Organization);
		MethodOfCancelingTransactions = Common.ObjectAttributeValue(PostingGenerationSetting, "MethodOfCancelingTransactions");
	Else
		TransactionGenerationSettings = Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings();
		MethodOfCancelingTransactions = TransactionGenerationSettings.MethodOfCancelingTransactions;
	EndIf;
	
	FinancialAccountingOfGeneralPurpose.AddTypesOfInvalidTransactions(MethodOfCancelingTransactions,
		Items.PostingType.ChoiceList);
	FinancialAccountingOfGeneralPurpose.AddTypesOfInvalidTransactions(MethodOfCancelingTransactions,
		Items.TransactionsWithoutCorrespondencePostingType.ChoiceList);
	
EndProcedure

#EndRegion

&AtClientAtServerNoContext
Procedure CalculateResultsOfTransactionsWithoutCorrespondence(ThisForm)
	
	Items = ThisForm.Items;
	
	ThisForm.TotalAmount_5Dr = 0;
	ThisForm.TotalAmount_5Cr = 0;
	ThisForm.ResultIsSumOfDrSubmission = 0;
	ThisForm.ResultIsSumOfCrRepresentation = 0;
	For Each Record In ThisForm.TransactionsWithoutCorrespondence Do
		ThisForm.TotalAmount_5Dr = ThisForm.TotalAmount_5Dr + ?(Record.RecordType = ThisForm.TypeOfMovementDebit, Record.Sum, 0);
		ThisForm.TotalAmount_5Cr = ThisForm.TotalAmount_5Cr + ?(Record.RecordType = ThisForm.TypeOfMovementCredit, Record.Sum, 0);
		ThisForm.ResultIsSumOfDrSubmission = ThisForm.ResultIsSumOfDrSubmission + ?(Record.RecordType = ThisForm.TypeOfMovementDebit, Record.PresentationAmount, 0);
		ThisForm.ResultIsSumOfCrRepresentation = ThisForm.ResultIsSumOfCrRepresentation + ?(Record.RecordType = ThisForm.TypeOfMovementCredit, Record.PresentationAmount, 0);
	EndDo;
	
	If ThisForm.TotalAmount_5Dr <> ThisForm.TotalAmount_5Cr Then
		Items.SumDr.FooterTextColor = ThisForm.OverdueDataColor;
		Items.SumCr.FooterTextColor = ThisForm.OverdueDataColor;
	Else
		Items.SumDr.FooterTextColor = New Color();
		Items.SumCr.FooterTextColor = New Color();
	EndIf;
	
	If ThisForm.ResultIsSumOfDrSubmission <> ThisForm.ResultIsSumOfCrRepresentation Then
		Items.PresentationAmountDr.FooterTextColor = ThisForm.OverdueDataColor;
		Items.PresentationAmountCr.FooterTextColor = ThisForm.OverdueDataColor;
	Else
		Items.PresentationAmountDr.FooterTextColor = New Color();
		Items.PresentationAmountCr.FooterTextColor = New Color();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence()
	
	For Each Record In TransactionsWithoutCorrespondence Do
		
		Record.SumDr = ?(Record.RecordType = TypeOfMovementDebit, Record.Sum, 0);
		Record.SumCr = ?(Record.RecordType = TypeOfMovementCredit, Record.Sum, 0);
		Record.PresentationAmountDr = ?(Record.RecordType = TypeOfMovementDebit, Record.PresentationAmount, 0);
		Record.PresentationAmountCr = ?(Record.RecordType = TypeOfMovementCredit, Record.PresentationAmount, 0);
		Record.TypeOfMovementIndex = 
			TypeOfMovementWithoutCorrelationIndexOfImage(
				Record.RecordType, Record.Active, Record.Sum, ThisObject);
		
	EndDo;
	
	CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Function TypeOfMovementWithoutCorrelationIndexOfImage(RecordType, Active, Sum, ThisForms)
	
	If RecordType = ThisForms.TypeOfMovementDebit And Sum <> 0 Then
		Return 1;
	ElsIf RecordType = ThisForms.TypeOfMovementCredit And Sum <> 0 Then
		Return 2;
	Else
		Return 0;
	EndIf;
	
EndFunction



#EndRegion
