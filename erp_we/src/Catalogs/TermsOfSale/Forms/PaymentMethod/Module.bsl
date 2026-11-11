#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	UseSimplifiedPaymentScheme = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	
	FillPropertyValues(Object, Parameters);
	Object.PaymentScheduleSteps.Clear();
	
	ThisIsACommission = Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent;
	ThisIsTransferToStorage = Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	ThisIsSubPrincipalDelivery = Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal;
	TheseAreCalculationsOnInvoices = Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
	UseShipmentWithDeferredTransferOfTitle =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0");
	CalledFormID = Parameters.UUID;
	FillInPaymentStagesFromTemporaryStorageServer(Parameters.AddressInTempStorage);
	CalculateTotalsOfAgreementWithClient(ThisObject);
	
	If ThisIsACommission Then
		
		ItemArray = New Array;
		ItemArray.Add("DecorationPrepayment");
		ItemArray.Add("ShiftPrepayment");
		ItemArray.Add("CountdownOptionPrepayment");
		ItemArray.Add("PaymentPercentagePrepayment");
		ItemArray.Add("PercentageOfTheDepositForTheContainerPrepayment");
		ItemArray.Add("PercentageOfPaymentCredit");
		ItemArray.Add("ThePercentageOfTheDepositForTheContainerLoan");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", False);
		
		PercentageOfPaymentCredit      = 100;
		ThePercentageOfTheDepositForTheContainerLoan = 100;
		
	EndIf;
	
	If ThisIsACommission Or ThisIsTransferToStorage Or TheseAreCalculationsOnInvoices Then
		
		Items.PaymentScheduleStepsCalculateFrom.ListChoiceMode = True;
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromShipmentDate);
		
		Items.CreditReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		Items.CreditReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromShipmentDate);
		
		Items.CountdownOptionPrepayment.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		
		If UseShipmentWithDeferredTransferOfTitle Then
			Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods);
			Items.CreditReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods);
		EndIf;
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.Formula);
		
	Else
		
		Items.PaymentScheduleStepsCalculateFrom.ListChoiceMode = True;
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate);
		If GetFunctionalOption("NotBaseVersion") Then
			Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromApprovalDate);
		EndIf;
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromShipmentDate);
		
		Items.CreditReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate);
		If GetFunctionalOption("NotBaseVersion") Then
			Items.CreditReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromApprovalDate);
		EndIf;
		Items.CreditReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		Items.CreditReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromShipmentDate);
		
		Items.CountdownOptionPrepayment.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate);
		If GetFunctionalOption("NotBaseVersion") Then
			Items.CountdownOptionPrepayment.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromApprovalDate);
		EndIf;
		Items.CountdownOptionPrepayment.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		
		Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision);
		
		If UseShipmentWithDeferredTransferOfTitle Then
			Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods);
			Items.CreditReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods);
		EndIf;
		
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.Formula);
		
	EndIf;
	
	Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment);
	Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.CreditAfterShipment);
	Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.CreditPlanned);
	
	If UseSimplifiedPaymentScheme Then
		Items.GroupPages.CurrentPage = Items.PageSimplifiedScheme;
		TMCommonUseClientServer.SetFormItemProperty(Items, "AdvancedSetupPage", "Visible", False);
	Else
		Items.GroupPages.CurrentPage = Items.AdvancedSetupPage;
		TMCommonUseClientServer.SetFormItemProperty(Items, "PageSimplifiedScheme", "Visible", False);
	EndIf;
	
	ItemArray = New Array;
	ItemArray.Add("ThePercentageOfTheDepositForTheContainerLoan");
	ItemArray.Add("PercentageOfTheDepositForTheContainerPrepayment");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemArray, "Visible", Object.PackageDepositIsRequired);
	
	DeferredPaymentMode = ValueIsFilled(Object.Calendar);
	SetCalendarAvailability(ThisForm);
	
	CashServer.ExcludeUnavailableFormsOfPayment(Items.PaymentMethod);
	
	Items.DeferredPaymentMode.Enabled = AccessRight("Update", Metadata.Catalogs.TermsOfSale);
	Items.CalendarExtended.Enabled = AccessRight("Update", Metadata.Catalogs.TermsOfSale);
	Items.AccountingForDeferralByCalendarDays.Enabled = AccessRight("Update", Metadata.Catalogs.TermsOfSale);
	Items.AccountingForDeferralOnTheProductionCalendar.Enabled = AccessRight("Update", Metadata.Catalogs.TermsOfSale);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	WindowOptionsKey = String(New UUID);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ClosingInProgress And Modified And Not Done And Not Exit Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatma'"));
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Tất cả dữ liệu đã thay đổi sẽ bị mất. Đóng biểu mẫu?';
																						|ru = 'Все измененные данные будут потеряны. Закрыть форму?';
																						|en = 'All changed data will be lost. Close the form?'; fa = 'All changed data will be lost. Close the form?';
																						|it = 'Tutti i dati modificati andranno persi. Chiudere il form?';
																						|pl = 'Wszystkie zmodyfikowane dane zostaną utracone. Chcesz zamknąć formularz?';
																						|tr = 'Tüm değişiklikler kaybolacak. Kapatılsın mı?'"), ButtonsList);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = "Close" Then
		ClosingInProgress = True;
		Close();
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtServer
Procedure FillInPaymentStagesFromTemporaryStorageServer(AddressInTempStorage)
	
	PaymentSteps = GetFromTempStorage(AddressInTempStorage);
	
	If UseSimplifiedPaymentScheme Then
		
		For Each CurRow In PaymentSteps Do
		
			If CurRow.PaymentOption = Enums.CustomerPaymentControlOptions.CreditAfterShipment
				Or CurRow.PaymentOption = Enums.CustomerPaymentControlOptions.CreditPlanned Then
				PercentageOfPaymentCredit = PercentageOfPaymentCredit + CurRow.PaymentPercentage;
				If Object.PackageDepositIsRequired Then
					ThePercentageOfTheDepositForTheContainerLoan = ThePercentageOfTheDepositForTheContainerLoan + CurRow.PackageDepositPercentage;
				EndIf;
				ShiftCredit = Max(ShiftCredit, CurRow.Move);
				CreditReferenceOption = CurRow.CalculateFrom;
			ElsIf Not ThisIsACommission Then //the advance and prepayment are summed up in the total amount
				PaymentPercentagePrepayment = PaymentPercentagePrepayment + CurRow.PaymentPercentage;
				If Object.PackageDepositIsRequired Then
					PercentageOfTheDepositForTheContainerPrepayment = PercentageOfTheDepositForTheContainerPrepayment + CurRow.PackageDepositPercentage;
				EndIf;
				ShiftPrepayment = Max(ShiftPrepayment, CurRow.Move);
				CountdownOptionPrepayment = CurRow.CalculateFrom;
			EndIf;
			
		EndDo;
		
		If ThisIsACommission Then
			PercentageOfPaymentCredit      = 100;
			ThePercentageOfTheDepositForTheContainerLoan = 100;
		EndIf;
		
	Else
		For Each CurRow In PaymentSteps Do
			NewRow = Object.PaymentScheduleSteps.Add();
			FillPropertyValues(NewRow, CurRow);
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsAfterDeleteRow(Item)
	
	CalculateTotalsOfAgreementWithClient(ThisForm);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotalsOfAgreementWithClient(ThisForm);
	SortStages();
	
EndProcedure

&AtClient
Procedure DeferredPaymentModeOnChange(Item)
	
	SetCalendarAvailability(ThisForm);
	
	If DeferredPaymentMode = 1 Then
		FillProductionCalendarOnServer();
	Else
		Object.Calendar = PredefinedValue("Catalog.BusinessCalendars.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentPercentagePrepaymentOnChange(Item)
	
	PaymentPercentageOnChange(PaymentPercentagePrepayment, PercentageOfPaymentCredit);
	
EndProcedure

&AtClient
Procedure PercentageOfPaymentCreditOnChange(Item)
	
	PaymentPercentageOnChange(PercentageOfPaymentCredit, PaymentPercentagePrepayment);
	
EndProcedure

&AtClient
Procedure PercentageOfTheDepositForTheContainerPrepaymentOnChange(Item)
	
	PaymentPercentageOnChange(PercentageOfTheDepositForTheContainerPrepayment, ThePercentageOfTheDepositForTheContainerLoan);
	
EndProcedure

&AtClient
Procedure ThePercentageOfTheDepositForTheContainerLoanOnChange(Item)
	
	PaymentPercentageOnChange(ThePercentageOfTheDepositForTheContainerLoan, PercentageOfTheDepositForTheContainerPrepayment);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentScheduleSteps

&AtClient
Procedure PaymentScheduleStepsCalculateFromOnChange(Item)
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	If CurrentData <> Undefined Then;
		
		If CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.Formula") Then
			CallbackDescription = New CallbackDescription("PaymentStagesReferenceOptionOnChangeCompletion",ThisObject);
			OpenForm("Catalog.FormulasForCalculatingPaymentDate.Form.ChoiceForm",,ThisObject,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
		Else
			CurrentData.Formula = Undefined;
			PaymentStepsClient.EliminateContradictionBetweenPaymentOptionAndReferenceOption(CurrentData);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsPaymentOptionOnChange(Item)
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	If CurrentData <> Undefined Then
		
		If CurrentData.PaymentOption <> PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment")
			And CurrentData.PaymentOption <> PredefinedValue("Enum.CustomerPaymentControlOptions.CreditPlanned")
			And (CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate")
				Or CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods")) Then
			CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate");
		ElsIf CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate") 
				And CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment") Then
			CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate");
		EndIf;
		
	EndIf;
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If Modified And UseSimplifiedPaymentScheme Then
		FillInPaymentStagesUsingFormDetails();
	EndIf;
	
	If Not Modified Then
		
		Close();
		
	ElsIf PaymentIsCorrect() Then
		
		Done = True;
		ObjectStructure = New Structure();
		ObjectStructure.Insert("PaymentMethod", Object.PaymentMethod);
		ObjectStructure.Insert("Calendar", Object.Calendar);
		ObjectStructure.Insert("AddressInTempStorage", PutItInTemporaryStorageOnServer());
		
		Close(ObjectStructure);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.PercentageIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.LineNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = New DataCompositionField("LineNumberOfFullPayment");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LineNumberOfFullPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPackageDepositPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.DepositPercentageIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPackageDepositPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.LineNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = New DataCompositionField("LineNumberOfDepositFullPayment");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LineNumberOfDepositFullPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPackageDepositPercentage.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.PackageDepositPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.PaymentPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPackageDepositPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PackageDepositIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentageOfPaymentCredit.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentPercentagePrepayment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalPaymentPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 100;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentageOfPaymentCredit.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentPercentagePrepayment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalPaymentPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 100;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ThePercentageOfTheDepositForTheContainerLoan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentageOfTheDepositForTheContainerPrepayment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepositPercentageTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 100;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ThePercentageOfTheDepositForTheContainerLoan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentageOfTheDepositForTheContainerPrepayment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepositPercentageTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 100;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);
	
	
EndProcedure

&AtServer
Function PaymentIsCorrect()

	Cancel = False;
	NumberOfStages = Object.PaymentScheduleSteps.Count();
	
	If Not UseSimplifiedPaymentScheme Then
		SortStages();
	EndIf;
	
	If Object.AvailableToExternalUsers And Object.PaymentScheduleSteps.Count() = 0 Then
		
		If UseSimplifiedPaymentScheme Then
			ErrorText = NStr("vi = 'Thỏa thuận hợp lệ đối với người sử dụng ngoài. Cần điền ít nhất một trong các giai đoạn';
							|ru = 'Соглашение доступно внешним пользователям. Необходимо заполнить хотя бы один из этапов';
							|en = 'Agreement is available for external users. Populate at least one stage'; fa = 'Agreement is available for external users. Populate at least one stage';
							|it = 'L''accordo è disponibile per gli utenti esterni. È necessario compilare almeno una delle fasi';
							|pl = 'Porozumienie jest dostępne dla użytkowników zewnętrznych. Należy wypełnić chociażby jeden etap';
							|tr = 'Anlaşma, harici kullanıcılar tarafından kullanılabilir. Aşamalardan en az birini doldurmanız gerekmektedir'");
			ErrorAddress = "PercentageOfPaymentCredit";
		Else
			ErrorText = NStr("vi = 'Thỏa thuận hợp lệ đối với người sử dụng ngoài. Cần điền danh sách ""Các giai đoạn trong lịch thanh toán""';
							|ru = 'Соглашение доступно внешним пользователям. Необходимо заполнить список ""Этапы графика оплаты""';
							|en = 'The agreement is available for external users. Payment milestones are required.'; fa = 'The agreement is available for external users. Payment milestones are required.';
							|it = 'L''accordo è disponibile per gli utenti esterni. È necessario compilare l''elenco ""Fasi del programma di pagamento""';
							|pl = 'Porozumienie jest dostępne dla użytkowników zewnętrznych. Należy wypełnić listę ""Etapy harmonogramu płatności""';
							|tr = 'Anlaşma, harici kullanıcılar tarafından kullanılabilir. ""Ödeme Planı Aşamaları"" listesini doldurmanız gerekmektedir'");
			ErrorAddress = "Object.PaymentScheduleSteps";
		EndIf;
		
		Common.MessageToUser(ErrorText, , ErrorAddress, ,Cancel);
		
	EndIf;
	
	For CurIndex__ = 0 To Object.PaymentScheduleSteps.Count()-1 Do
		
		CurRow = Object.PaymentScheduleSteps[CurIndex__]; // LineOfATabularSection
		
		ErrorAddress = " " + NStr("vi = 'tại dòng %LineNumber% trong danh sách ""Các giai đoạn trong lịch thanh toán""';
									|ru = 'в строке %LineNumber% списка ""Этапы графика оплаты""';
									|en = 'in line %LineNumber% of the ""Payment milestones"" list'; fa = 'in line %LineNumber% of the ""Payment milestones"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Fasi del programma di pagamento""';
									|pl = 'w wierszu %LineNumber% listy ""Этапы графика оплаты""';
									|tr = '""ödeme planı aşamaları"" listenin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", CurRow.LineNumber);
		
		If Not ValueIsFilled(CurRow.PaymentOption) Then
			
			If Not UseSimplifiedPaymentScheme Then
				ErrorText = NStr("vi = 'Chưa điền cột ""Phương án kiểm soát""';
								|ru = 'Не заполнена колонка ""Вариант контроля""';
								|en = 'The ""Control option"" column is not filled in'; fa = 'The ""Control option"" column is not filled in';
								|it = 'Colonna ""Variante di controllo"" non compilata';
								|pl = 'Nie wypełniono kolumny ""Wariant kontroli""';
								|tr = '""Kontrol seçeneği"" sütunu boş'");
				Common.MessageToUser(
					ErrorText + ErrorAddress,
					,
					CommonClientServer.PathToTabularSection("Object.PaymentScheduleSteps", CurRow.LineNumber, "PaymentOption"),
					,
					Cancel);
			Else
				CurRow.PaymentOption = Enums.CustomerPaymentControlOptions.CreditAfterShipment;
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(CurRow.CalculateFrom) Then
			
			If UseSimplifiedPaymentScheme Then
				ErrorText = NStr("vi = 'Chưa điền cột ""Phương án đếm ngược""';
								|ru = 'Не заполнена колонка ""Вариант отсчета""';
								|en = 'The ""Calculate from"" column is not filled in'; fa = 'The ""Calculate from"" column is not filled in';
								|it = 'Non è stata compilata la colonna ""Variante di calcolo""';
								|pl = 'Nie wypełniono kolumny ""Wariant odliczenia""';
								|tr = '""Referans seçeneği"" sütunu boş'");
				Common.MessageToUser(
					ErrorText,
					,
					?(CurRow.PaymentOption = Enums.CustomerPaymentControlOptions.CreditAfterShipment,"CreditReferenceOption","CountdownOptionPrepayment"),
					,
					Cancel);
			Else
				ErrorText = NStr("vi = 'Chưa điền cột ""Phương án đếm ngược""';
								|ru = 'Не заполнена колонка ""Вариант отсчета""';
								|en = 'The ""Calculate from"" column is not filled in'; fa = 'The ""Calculate from"" column is not filled in';
								|it = 'Non è stata compilata la colonna ""Variante di calcolo""';
								|pl = 'Nie wypełniono kolumny ""Wariant odliczenia""';
								|tr = '""Referans seçeneği"" sütunu boş'");
				Common.MessageToUser(
					ErrorText + ErrorAddress,
					,
					CommonClientServer.PathToTabularSection("Object.PaymentScheduleSteps", CurRow.LineNumber, "CalculateFrom"),
					,
					Cancel);
			EndIf;
			
		EndIf;
		
		If Object.PackageDepositIsRequired Then
			If Not ValueIsFilled(CurRow.PaymentPercentage)
				And Not ValueIsFilled(CurRow.PackageDepositPercentage) Then
				
				If UseSimplifiedPaymentScheme Then
					ErrorText = NStr("vi = 'Đối với giai đoạn này cần chỉ ra tỷ lệ phần trăm thanh toán hoặc phần trăm ký cược bao bì';
									|ru = 'Для этапа должен быть указан процент платежа или процент залога за тару';
									|en = 'Percentage of payment and packaging deposit should be specified for the step'; fa = 'Percentage of payment and packaging deposit should be specified for the step';
									|it = 'Per la fase, è necessario specificare la percentuale di pagamento o la percentuale di deposito per la confezione';
									|pl = 'Dla etapu należy wskazać procent płatności lub procent kaucji za tarę';
									|tr = 'Aşama için bir ödeme yüzdesi veya dara depozitosunun yüzdesi belirtilmelidir'");
					Common.MessageToUser(
						ErrorText,
						,
						?(CurRow.PaymentOption = Enums.CustomerPaymentControlOptions.CreditAfterShipment,"PercentageOfPaymentCredit","PaymentPercentagePrepayment"),
						,
						Cancel);
				Else
					ErrorText = NStr("vi = 'Đối với giai đoạn này cần chỉ ra tỷ lệ phần trăm thanh toán hoặc phần trăm ký cược bao bì';
									|ru = 'Для этапа должен быть указан процент платежа или процент залога за тару';
									|en = 'Percentage of payment and packaging deposit should be specified for the step'; fa = 'Percentage of payment and packaging deposit should be specified for the step';
									|it = 'Per la fase, è necessario specificare la percentuale di pagamento o la percentuale di deposito per la confezione';
									|pl = 'Dla etapu należy wskazać procent płatności lub procent kaucji za tarę';
									|tr = 'Aşama için bir ödeme yüzdesi veya dara depozitosunun yüzdesi belirtilmelidir'");
					Common.MessageToUser(
						ErrorText + ErrorAddress,
						,
						CommonClientServer.PathToTabularSection(
							"Object.PaymentScheduleSteps",
							CurRow.LineNumber,
							"PaymentPercentage"),
						,
						Cancel);
				EndIf;
				
			EndIf;
		Else
			If Not ValueIsFilled(CurRow.PaymentPercentage) Then
				
				If UseSimplifiedPaymentScheme Then
					ErrorText = NStr("vi = 'Chưa điền tỷ lệ phần trăm thanh toán';
									|ru = 'Не заполнен процент платежа';
									|en = 'Payment percentage is not filled in'; fa = 'Payment percentage is not filled in';
									|it = 'Percentuale di pagamento non compilata';
									|pl = 'Nie wypełniono procentu płatności';
									|tr = 'Ödeme yüzdesi boş'");
					Common.MessageToUser(
						ErrorText,
						,
						?(CurRow.PaymentOption = Enums.CustomerPaymentControlOptions.CreditAfterShipment,"PercentageOfPaymentCredit","PaymentPercentagePrepayment"),
						,
						Cancel);
				Else
					ErrorText = NStr("vi = 'Chưa điền cột ""Phần trăm thanh toán""';
									|ru = 'Не заполнена колонка ""Процент платежа""';
									|en = 'Column ""Payment percentage"" is not filled in'; fa = 'Column ""Payment percentage"" is not filled in';
									|it = 'La colonna ""Percentuale di pagamento"" non è compilata';
									|pl = 'Nie wypełniono kolumny ""Процент платежа""';
									|tr = '""Ödeme yüzdesi"" sütunu boş'");
					Common.MessageToUser(
						ErrorText + ErrorAddress,
						,
						CommonClientServer.PathToTabularSection("Object.PaymentScheduleSteps", CurRow.LineNumber, "PaymentPercentage"),
						,
						Cancel);
				EndIf;
				
			EndIf;
		EndIf;
		
	EndDo;
	
	If NumberOfStages > 0 Then
		
		If Object.PaymentScheduleSteps.Total("PaymentPercentage") <> 100 Then
			
			ErrorText = NStr("vi = 'Phần trăm thanh toán theo tất cả giai đoạn phải bằng 100%';
							|ru = 'Процент платежей по всем этапам должен быть равен 100%';
							|en = 'Payment percentage at all stages should be equal to 100 %'; fa = 'Payment percentage at all stages should be equal to 100 %';
							|it = 'La percentuale di pagamento per tutte le fasi deve essere pari al 100%';
							|pl = 'Procent płatności dla wszystkich etapów powinien wynosić 100%';
							|tr = 'Tüm aşamalar için ödeme yüzdesi 100% olmalıdır'");
			If UseSimplifiedPaymentScheme Then
				ErrorAddress = "PercentageOfPaymentCredit";
			Else
				ErrorAddress = "Object.PaymentScheduleSteps";
			EndIf;
			
			Common.MessageToUser(ErrorText, , ErrorAddress, , Cancel);
			
		EndIf;
		
		If Object.PackageDepositIsRequired
			And Object.PaymentScheduleSteps.Total("PackageDepositPercentage") <> 100 Then
			
			ErrorText = NStr("vi = 'Tỷ lệ phần trăm ký cược bao bì theo tất cả giai đoạn phải bằng 100%';
							|ru = 'Процент залога за тару по всем этапам должен быть равен 100%';
							|en = 'Percentage of the packaging deposit at all stages should be equal to 100%'; fa = 'Percentage of the packaging deposit at all stages should be equal to 100%';
							|it = 'La percentuale del deposito per la confezione in tutte le fasi dovrebbe essere pari al 100%';
							|pl = 'Procent kaucji za tarę dla wszystkich etapów powinien wynosić 100%';
							|tr = 'Tüm aşamalar için dara depozitosunun yüzdesi 100% olmalıdır'");
			If UseSimplifiedPaymentScheme Then
				ErrorAddress = "ThePercentageOfTheDepositForTheContainerLoan";
			Else
				ErrorAddress = "Object.PaymentScheduleSteps";
			EndIf;
			
			Common.MessageToUser(ErrorText, , ErrorAddress, , Cancel);
			
		EndIf;
		
		If ThisIsACommission Then
			
			For Each PaymentScheduleStage In Object.PaymentScheduleSteps Do
				
				If PaymentScheduleStage.PaymentOption <> Enums.CustomerPaymentControlOptions.CreditAfterShipment
					And PaymentScheduleStage.PaymentOption <> Enums.CustomerPaymentControlOptions.CreditPlanned Then
					
					ErrorText = NStr("vi = 'Không nên sử dụng phương án thanh toán ""%PaymentOption%""';
									|ru = 'Вариант оплаты ""%PaymentOption%"" нельзя использовать';
									|en = 'Cannot use: %PaymentOption%'; fa = 'Cannot use: %PaymentOption%';
									|it = 'Impossibile utilizzare l''opzione di pagamento ""%PaymentOption%""';
									|pl = 'Wariant płatności ""%PaymentOption%"" nie może być użyty';
									|tr = '""%PaymentOption%"" ödeme seçeneği kullanılamaz'") + Chars.LF;
					ErrorText = ErrorText + NStr("vi = 'với giao dịch kinh doanh được thiết lập ""%BusinessOperation%""';
												|ru = 'при установленной хозяйственной операции ""%BusinessOperation%""';
												|en = 'with a set ""%BusinessOperation%"" business transaction'; fa = 'with a set ""%BusinessOperation%"" business transaction';
												|it = 'Durante la transazione commerciale stabilita ""%BusinessOperation%""';
												|pl = 'z ustaloną transakcją biznesową ""%BusinessOperation%""';
												|tr = '""%BusinessOperation%"" ticari işleminin yapılandırılma sırasında'");
					ErrorText = StrReplace(ErrorText, "%PaymentOption%", PaymentScheduleStage.PaymentOption);
					ErrorText = StrReplace(ErrorText, "%BusinessOperation%", Object.BusinessOperation);
					
					Common.MessageToUser(
						ErrorText,
						,
						"Object." + CommonClientServer.PathToTabularSection("PaymentScheduleSteps", PaymentScheduleStage.LineNumber,"PaymentOption"),
						,
						Cancel);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	If DeferredPaymentMode = 1 And Not ValueIsFilled(Object.Calendar) Then
		
		ErrorText = NStr("vi = 'Chưa chỉ ra lịch để tính thời hạn hoãn lại theo ngày làm việc.';
						|ru = 'Не указан календарь для учета отсрочки по рабочим дням.';
						|en = 'Calendar for deferred payments by work days is not specified.'; fa = 'Calendar for deferred payments by work days is not specified.';
						|it = 'Non è indicato il calendario per la contabilità di posticipazione nei giorni lavorativi.';
						|pl = 'Nie wskazano kalendarza dla ewidencji prolongaty w dni robocze.';
						|tr = 'İş gününe göre ertelemeyi açıklamak için herhangi bir takvim belirtilmemiştir.'");
		Common.MessageToUser(ErrorText, , "Object.Calendar", , Cancel);
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

&AtServer
Function PutItInTemporaryStorageOnServer()
	Return PutToTempStorage(Object.PaymentScheduleSteps.Unload(), CalledFormID);
EndFunction

&AtClientAtServerNoContext
Procedure CalculateTotalsOfAgreementWithClient(Form)
	
	Form.TotalPaymentPercentage = 0;
	Form.DepositPercentageTotal = 0;
	Form.LineNumberOfFullPayment = 0;
	Form.LineNumberOfDepositFullPayment = 0;
	
	If Form.UseSimplifiedPaymentScheme Then
		
		Form.TotalPaymentPercentage = Form.PercentageOfPaymentCredit + Form.PaymentPercentagePrepayment;
		Form.DepositPercentageTotal   = Form.ThePercentageOfTheDepositForTheContainerLoan + Form.PercentageOfTheDepositForTheContainerPrepayment;
		
	Else
		
		For Each CurRow In Form.Object.PaymentScheduleSteps Do
			
			Form.TotalPaymentPercentage = Form.TotalPaymentPercentage + CurRow.PaymentPercentage;
			CurRow.PercentageIsFilledInIncorrectly = (Form.TotalPaymentPercentage > 100);
			If Form.TotalPaymentPercentage = 100 Then
				Form.LineNumberOfFullPayment = CurRow.LineNumber;
			EndIf;
			
			Form.DepositPercentageTotal = Form.DepositPercentageTotal + CurRow.PackageDepositPercentage;
			CurRow.DepositPercentageIsFilledInIncorrectly = (Form.DepositPercentageTotal > 100);
			If Form.DepositPercentageTotal = 100 Then
				Form.LineNumberOfDepositFullPayment = CurRow.LineNumber;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillProductionCalendarOnServer()
	
	CalendarSchedules.FillBusinessCalendarInForm(ThisForm, "Object.Calendar");
	
EndProcedure

&AtClient
Procedure FillInPaymentStagesUsingFormDetails()
	
	Object.PaymentScheduleSteps.Clear();
	
	If Not ThisIsACommission 
		And (PaymentPercentagePrepayment > 0
			Or (Object.PackageDepositIsRequired And PercentageOfTheDepositForTheContainerPrepayment > 0)) Then
		NewRow = Object.PaymentScheduleSteps.Add();
		NewRow.PaymentOption       = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment");
		NewRow.Move               = ShiftPrepayment;
		NewRow.CalculateFrom      = CountdownOptionPrepayment;
		NewRow.PaymentPercentage      = PaymentPercentagePrepayment;
		NewRow.PackageDepositPercentage = PercentageOfTheDepositForTheContainerPrepayment
	EndIf;
	
	If PercentageOfPaymentCredit > 0 
		Or (Object.PackageDepositIsRequired And ThePercentageOfTheDepositForTheContainerLoan > 0) Then
		NewRow = Object.PaymentScheduleSteps.Add();
		NewRow.PaymentOption       = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment");
		NewRow.Move               = ShiftCredit;
		NewRow.CalculateFrom      = CreditReferenceOption;
		NewRow.PaymentPercentage      = PercentageOfPaymentCredit;
		NewRow.PackageDepositPercentage = ThePercentageOfTheDepositForTheContainerLoan;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCalendarAvailability(Form)
	
	ItemArray = New Array;
	ItemArray.Add("CalendarSimplified");
	ItemArray.Add("CalendarExtended");
	
	CalendarOption = Form.DeferredPaymentMode = 1;
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items, ItemArray, "Enabled", CalendarOption);
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items, ItemArray, "AutoMarkIncomplete", CalendarOption);
	
EndProcedure

&AtClient
Procedure PaymentPercentageOnChange(Percent, DependentPercentage)

	DependentPercentage = 100 - Percent;
	CalculateTotalsOfAgreementWithClient(ThisForm);

EndProcedure

&AtServer
Procedure SortStages()
	
	OrderOfReferenceOptions = PaymentStepsClientServer.OrderOfReferenceOptions();
	For Each PaymentStage In Object.PaymentScheduleSteps Do
		PaymentStage.PaymentOptionNumber = OrderOfReferenceOptions[PaymentStage.CalculateFrom];
	EndDo;
	
	Object.PaymentScheduleSteps.Sort("PaymentOptionNumber,Move");
	
EndProcedure

&AtClient
Procedure PaymentStagesReferenceOptionOnChangeCompletion(Result, AdditionalParameters) Export
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	If Result = Undefined Then
		CurrentData.CalculateFrom = Undefined;
		CurrentData.Formula = Undefined;
		Return;
	EndIf;
	
	CurrentData.Formula = Result;
	PaymentStepsClient.EliminateContradictionBetweenPaymentOptionAndReferenceOption(CurrentData);
	
EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
