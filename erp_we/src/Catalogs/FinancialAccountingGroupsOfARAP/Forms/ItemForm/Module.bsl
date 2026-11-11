#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("ChoiceParameters") Then
		Catalogs.FinancialAccountingGroupsOfARAP.ConvertSelectionParametersSelection(Parameters.ChoiceParameters);
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	Items.GroupRecordInInternationalAccounting.Visible = False;
	GetStateOfInternationalAccountingAccounts();
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "AccountRefinementSettingsChanged" Then
		GetStateOfInternationalAccountingAccounts();
	EndIf;
	GLAccountSettingsClient.FinishedSettingUpAccountingAccounts(ThisObject, EventName, Parameter);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Cancel Then
		Return;
	EndIf;
	GLAccountSettingsServer.WhenWritingAccountSettingsObject(ThisObject, Cancel, CurrentObject, WriteParameters);
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Cancel Then
		Return;
	EndIf;
	GLAccountSettingsServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ApplicabilityOnChange(Item)
	
	Object.CustomersARAPAccounting = False;
	Object.VendorsARAPAccounting = False;
	Object.CommissionAgentsARAPAccounting = False;
	Object.ConsignorsARAPAccounting = False;
	Object.PurchaseSettlementsWithConsignors = False;
	Object.SettlementsWithSubcontractor = False;
	Object.ProvidersARAP = False;
	Object.CreditorsARAPAccounting = False;
	Object.DebtorsARAPAccounting = False;
	Object.LeaseContractARAPWithLessors = False;
	Object.BookingARAPAccounting = False;
	
	If Applicability = 1 Then
		Object.CustomersARAPAccounting = True;
	ElsIf Applicability = 2 Then
		Object.VendorsARAPAccounting = True;
	ElsIf Applicability = 3 Then
		Object.CommissionAgentsARAPAccounting = True;
	ElsIf Applicability = 4 Then
		Object.ConsignorsARAPAccounting = True;
	ElsIf Applicability = 8 Then
		Object.PurchaseSettlementsWithConsignors = True;
	ElsIf Applicability = 9 Then
		Object.SettlementsWithSubcontractor = True;
	ElsIf Applicability = 11 Then
		Object.ProvidersARAP = True;
	ElsIf Applicability = 5 Then
		Object.CreditorsARAPAccounting = True;
	ElsIf Applicability = 6 Then
		Object.DebtorsARAPAccounting = True;
	ElsIf Applicability = 7 Then
		Object.LeaseContractARAPWithLessors = True;
	ElsIf Applicability = 10 Then
		Object.BookingARAPAccounting = True;
	EndIf;
	GLAccountSettingsClientServer.OnChangeAttribute(ThisObject);
EndProcedure

&AtClient
Procedure ARAPAccountingCurrencyOnChange(Item)
	
	Modified = True;
	
	If ARAPAccountingCurrency = 0 Then
		Object.ARAPInCurrency = False;
		Object.ARAPAccountingInLocalAccountingCurrency = True;
	ElsIf ARAPAccountingCurrency = 1 Then
		Object.ARAPInCurrency = True;
		Object.ARAPAccountingInLocalAccountingCurrency = False;
	ElsIf ARAPAccountingCurrency = 2 Then
		Object.ARAPInCurrency = True;
		Object.ARAPAccountingInLocalAccountingCurrency = True;
	EndIf;
	GLAccountSettingsClientServer.OnChangeAttribute(ThisObject);
EndProcedure

#Region SettingUpAccountingAccounts_EventHandlersForFormHeaderElements

&AtClient
Procedure Attachable_OnChange_SettingUpAccountingAccounts(Item)
	GLAccountSettingsClient.OnChange(Item, ThisObject);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_StartOfSelection_SettingUpAccountingAccounts(Item, ChoiceData, StandardProcessing)
	GLAccountSettingsClient.StartChoice(ThisObject, Item, ChoiceData, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_Regulation_SettingUpAccountingAccounts(Item, Direction, StandardProcessing)
	GLAccountSettingsClient.Tuning(ThisObject, Item, Direction, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_Cleaning_SettingUpAccountingAccounts(Item, StandardProcessing)
	GLAccountSettingsClient.Clearing(ThisObject, Item, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
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
Procedure OnReadCreateAtServer()
	
	ArrayApplicability = New Array;
	
	UsePurchaseCommission               = GetFunctionalOption("UsePurchaseCommission");
	UseSalesCommission               = GetFunctionalOption("UseSalesCommission");
	UseLoanAndDepositContracts        = GetFunctionalOption("UseLoanAndDepositContracts");
	ProvideAgentServicesOnPurchaseToPrincipals  = GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals");
	UseProductionByThirdParty2_5          = GetFunctionalOption("UseProductionByThirdParty2_5");
	UseLeaseAgreements = NonCurrentAssets.VNAManagementIsUsed();
	UseGivers2_5                      = GetFunctionalOption("UseTollManufacturing2_5");
	CommissionBetweenOrganizations = ?(GetFunctionalOption("UseCustomerInvoiceIntercompany"),
		TMCommonUseCached.UseMethodForTransferringGoodsBetweenOrganizations(
			Enums.GoodsTransferMethods.TransferToCommissionAgent), False);
	
	ChoiceList = Items.Applicability.ChoiceList;
	ChoiceList.Clear();
	
	ChoiceList.Add(1, NStr("vi = 'khách hàng';
							|ru = 'клиентами';
							|en = 'customers'; fa = 'مشتریان';
							|it = 'con i clienti';
							|pl = 'przez klientów';
							|tr = 'müşterilerden'"));
	ChoiceList.Add(2, NStr("vi = 'nhà cung cấp';
							|ru = 'поставщиками';
							|en = 'vendors'; fa = 'تأمین‌کنندگان';
							|it = 'fornitori';
							|pl = 'przez dostawców';
							|tr = 'tedarikçilerden'"));
	If UseSalesCommission Or CommissionBetweenOrganizations Or Object.CommissionAgentsARAPAccounting Then
		ChoiceList.Add(3, NStr("vi = 'người nhận ký gửi / đại lý';
								|ru = 'комиссионерами / агентами';
								|en = 'agents or consignees'; fa = 'agents or consignees';
								|it = 'agente in conto vendita/agenti';
								|pl = 'komisantom / agentom';
								|tr = 'konsinyelerden / ajanlardan'"));
	EndIf;
	If UsePurchaseCommission Or CommissionBetweenOrganizations Or Object.ConsignorsARAPAccounting Then
		ChoiceList.Add(4, NStr("vi = 'bởi người đặt ký gửi bán hàng';
								|ru = 'комитентами по продаже';
								|en = 'sales consignors'; fa = 'sales consignors';
								|it = 'commitenti per le vendite';
								|pl = 'komitentami ds sprzedaży';
								|tr = 'satışa ilişkin göndericilerden'"));
	EndIf;
	If ProvideAgentServicesOnPurchaseToPrincipals Or Object.PurchaseSettlementsWithConsignors Then
		ChoiceList.Add(8, NStr("vi = 'bởi người đặt ký gửi mua hàng';
								|ru = 'комитентами по закупке';
								|en = 'purchase consignors'; fa = 'purchase consignors';
								|it = 'committenti per gli acquisti';
								|pl = 'komitentami ds zakupu';
								|tr = 'satın almaya ilişkin göndericilerden'"));
	EndIf;
	If UseLoanAndDepositContracts Or Object.DebtorsARAPAccounting Then
		ChoiceList.Add(6, NStr("vi = 'bởi người phải thu qua  tiền gửi (deposit), khoản vay';
								|ru = 'дебиторами по депозитам, займам';
								|en = 'debtors by deposits or loans'; fa = 'debtors by deposits or loans';
								|it = 'debitori su depositi, prestiti';
								|pl = 'przez dłużników według depozytów, pożyczek';
								|tr = 'mevduata, borca göre borçludan'"));
	EndIf;
	If UseLoanAndDepositContracts Or Object.CreditorsARAPAccounting Then
		ChoiceList.Add(5, NStr("vi = 'bởi người phải trả bằng tín dụng, các khoản vay';
								|ru = 'кредиторами по кредитам, займам';
								|en = 'creditors by credits or loans'; fa = 'creditors by credits or loans';
								|it = 'istituti di credito per prestiti, prestiti';
								|pl = 'przez wierzycieli według kredytów, pożyczek';
								|tr = 'kredilere, borçlara göre alacaklıdan'"));
	EndIf;
	If UseLeaseAgreements Or Object.LeaseContractARAPWithLessors Then
		ChoiceList.Add(7, NStr("vi = 'bởi người cho thuê';
								|ru = 'арендодателями';
								|en = 'lessors'; fa = 'lessors';
								|it = 'da parte dei locatori';
								|pl = 'lessors';
								|tr = 'mülk sahipleri'"));
	EndIf;
	If UseProductionByThirdParty2_5 Or Object.SettlementsWithSubcontractor Then
		ChoiceList.Add(9, NStr("vi = 'bởi người nhận gia công';
								|ru = 'переработчиками';
								|en = 'subcontractors'; fa = 'subcontractors';
								|it = 'da parte degli elaboratori';
								|pl = 'subcontractors';
								|tr = 'fason üreticiler'"));
	EndIf;
	If UseGivers2_5
		Or Object.ProvidersARAP Then
		ChoiceList.Add(11, NStr("vi = 'bởi người đặt gia công';
								|ru = 'давальцами';
								|en = 'providers'; fa = 'providers';
								|it = 'dei fornitori';
								|pl = 'providers';
								|tr = 'sağlayıcılar'"));
	EndIf;
	ChoiceList.Add(10, NStr("vi = 'bởi bên vận chuyển về đặt chỗ';
							|ru = 'перевозчиками по бронированию';
							|en = 'carriers by booking'; fa = 'carriers by booking';
							|it = 'ai vettori per prenotazione';
							|pl = 'przewoźnikami według rezerwacji';
							|tr = 'rezervasyona ilişkin taşıyıcılar'"));
	
	If Object.CustomersARAPAccounting Then
		ArrayApplicability.Add(1);
	EndIf;
	If Object.VendorsARAPAccounting Then
		ArrayApplicability.Add(2);
	EndIf;
	If Object.CommissionAgentsARAPAccounting Then
		ArrayApplicability.Add(3);
	EndIf;
	If Object.ConsignorsARAPAccounting Then
		ArrayApplicability.Add(4);
	EndIf;
	If Object.PurchaseSettlementsWithConsignors Then
		ArrayApplicability.Add(8);
	EndIf;
	If Object.SettlementsWithSubcontractor Then
		ArrayApplicability.Add(9);
	EndIf;
	If Object.ProvidersARAP Then
		ArrayApplicability.Add(11);
	EndIf;
	If Object.CreditorsARAPAccounting Then
		ArrayApplicability.Add(5);
	EndIf;
	If Object.DebtorsARAPAccounting Then
		ArrayApplicability.Add(6);
	EndIf;
	If Object.LeaseContractARAPWithLessors Then
		ArrayApplicability.Add(7);
	EndIf;
	If Object.BookingARAPAccounting Then
		ArrayApplicability.Add(10);
	EndIf;
	
	If ArrayApplicability.Count() = 1 Then
		Applicability = ArrayApplicability[0];
	Else
		Applicability = 0;
		SubstringsArray = New Array;
		For Each Item In ArrayApplicability Do
			ListItem = ChoiceList.FindByValue(Item);
			If ListItem <> Undefined Then
				SubstringsArray.Add(ListItem.Presentation);
			EndIf;
		EndDo;
		ChoiceList.Add(0, StrConcat(SubstringsArray, ", "));
	EndIf;
	GLAccountSettingsServer.WhenReadingCreatingAccountSettingsObject(ThisObject);
	Items.Applicability.ReadOnly = Not AccessRight("Edit", Metadata.Catalogs.FinancialAccountingGroupsOfARAP);
	
	PropertyValue = GetFunctionalOption("UseMultipleCurrencies");
	Items.TitleSettlementAccountingCurrency.Visible = PropertyValue;
	Items.PaymentAccountingCurrencyGroup.Visible = PropertyValue;
	
	If Object.ARAPInCurrency And Object.ARAPAccountingInLocalAccountingCurrency Then
		ARAPAccountingCurrency = 2;
	ElsIf Object.ARAPInCurrency Then
		ARAPAccountingCurrency = 1;
	ElsIf Object.ARAPAccountingInLocalAccountingCurrency Then
		ARAPAccountingCurrency = 0;
	Else
		ARAPAccountingCurrency = 0;
		Object.ARAPAccountingInLocalAccountingCurrency = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure GetStateOfInternationalAccountingAccounts()
	
	FinancialAccountingOfGeneralPurpose.SetVisibilityOfMFPSettings(
		Object.Ref,
		Items.GroupRecordInInternationalAccounting,
		Items.Find("ToConfigureAccountSpecification"));// for limited users, the element is cut from the form
	
EndProcedure

#EndRegion
