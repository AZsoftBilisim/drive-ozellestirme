//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("DocumentRef.ConditionsOfCustomerRebates") Then
		
		DocumentReference = FillingData; // DocumentRef.ConditionsOfCustomerRebates
		FillInAccordingToConditionOfCustomerRebates(DocumentReference);
		
	EndIf;
	
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array; // Array of String
	
	If TermDocument.IsEmpty() Then
		
		NotCheckedAttributeArray.Add("Counterparty");
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("BeginOfPeriod");
		NotCheckedAttributeArray.Add("PeriodEnding");
		NotCheckedAttributeArray.Add("Currency");
		NotCheckedAttributeArray.Add("Accruals");
		
	Else
		
		Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
		TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(TermDocument);
		
		If TermsAndConditionsAttributes.Count() > 0 Then
			
			If TermsAndConditionsAttributes.PartyCountDetails = Detailing.ByCounterparty Then
				
				NotCheckedAttributeArray.Add("Partner");
				
			ElsIf TermsAndConditionsAttributes.PartyCountDetails = Detailing.ByCustomer Then
				
				NotCheckedAttributeArray.Add("Counterparty");
				
			EndIf;
			
			CheckFixationOfCompositionOfSegmentsOfURB(Cancel, False, TermsAndConditionsAttributes);
			If Not Cancel Then
				CheckParticipantsAccordingToConditionOfRebates(TermsAndConditionsAttributes, Cancel);
			EndIf;
			MonitoringCompletionOfValidityPeriod(TermsAndConditionsAttributes, Cancel);
			
		Else
			
			NotCheckedAttributeArray.Add("Counterparty");
			NotCheckedAttributeArray.Add("Partner");
			NotCheckedAttributeArray.Add("BeginOfPeriod");
			NotCheckedAttributeArray.Add("PeriodEnding");
			NotCheckedAttributeArray.Add("Currency");
			NotCheckedAttributeArray.Add("Accruals");
			
		EndIf;
		
		CheckAccrualAmounts(Cancel);
		CheckAvailabilityOfSalesDocuments(Cancel);
		RebatesServer.CheckRebateKindOfTermsAndConditionsDocument(TermDocument, TermsAndConditionsAttributes, Cancel);
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		MessageText = NStr("vi = 'Cấm thay đổi chứng từ trong nút phụ trao đổi';
							|ru = 'Запрещено изменение документа в подчиненном узле обмена';
							|en = 'Cannot change the document in a subordinate exchange node'; fa = 'Cannot change the document in a subordinate exchange node';
							|it = 'Запрещено изменение документа в подчиненном узле обмена';
							|pl = 'Cannot change the document in a subordinate exchange node';
							|tr = 'Bağımlı değişim düğümündeki belgenin değiştirilmesi yasaktır'");
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		
	EndIf;
	
	If TermDocument.IsEmpty() Then
		
		MultipleCounterparties = False;
		SeveralPartners = False;
		
	Else
		
		TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(TermDocument);
		
		ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
		MultipleCounterparties = (TermsAndConditionsAttributes.PartyCountDetails = ShouldDetailCalculation.ByCustomer);
		SeveralPartners = (TermsAndConditionsAttributes.PartyCountDetails = ShouldDetailCalculation.ByCounterparty);
		
		If WriteMode = DocumentWriteMode.Posting Then
			
			ThereAreAccrualsForPeriod(TermsAndConditionsAttributes, Cancel);
			CheckFixationOfCompositionOfSegmentsOfURB(Cancel, True);
			CheckStatusOfCurrentURB(Cancel, True);
			
		EndIf;
		
	EndIf;
	
	SettlementAmount_ = Accruals.Total("AmountAccruedBonus");
	AmountAccrued = Accruals.Total("AmountBonusAccrued");
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

// Parameters:
//  ConditionOfRebates - DocumentRef.ConditionsOfCustomerRebates - fill-in data
//
Procedure FillInAccordingToConditionOfCustomerRebates(ConditionOfRebates)
	
	TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(ConditionOfRebates);
	
	TermDocument = ConditionOfRebates;
	Organization = TermsAndConditionsAttributes.Organization;
	BeginOfPeriod = TermsAndConditionsAttributes.ValidOnDate;
	PeriodEnding = TermsAndConditionsAttributes.ValidTo;
	Currency = TermsAndConditionsAttributes.Currency;
	
	If Not ValueIsFilled(Currency)
	   And TermsAndConditionsAttributes.SalesCalculationBase = Enums.RebateCalculationBases.RevenueARAPAccounting
	   And Not GetFunctionalOption("UseMultipleCurrencies") Then
		
		Currency = Catalogs.Currencies.GetDefaultCurrency();
		If Not ValueIsFilled(Currency) Then
			
			Raise NStr("vi = 'Không thể điền trường ""Tiền tệ"". Có thể là, trong cơ sở thông tin chưa nhập tiền tệ nào
								   |Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị"" - ""Công ty"" - ""Tiền tệ"".';
								   |ru = 'Не удалось заполнить поле ""Валюта"". Возможно, в информационной базе не введено ни одной валюты
								   |Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Предприятие""-""Валюты"".';
								   |en = 'Cannot fill the ""Currency"" field. There might be no currencies entered in the infobase.
								   |To set up, go to Master data and settings > Enterprise > Currencies.'; fa = 'Cannot fill the ""Currency"" field. There might be no currencies entered in the infobase.
								   |To set up, go to Master data and settings > Enterprise > Currencies.';
								   |it = 'Не удалось заполнить поле ""Валюта"". Возможно, в информационной базе не введено ни одной валюты
								   |Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Предприятие""-""Валюты"".';
								   |pl = 'Cannot fill the ""Currency"" field. There might be no currencies entered in the infobase.
								   |To set up, go to Master data and settings > Enterprise > Currencies.';
								   |tr = '""Düzenlenmiş Muhasebe Para Birimi"" alanı doldurulamadı. Infobase''te herhangi bir para birimi girilmemiş olabilir
								   |Ayarlamak için ""Master veri ve Yönetim""-""İş yeri""-""Para Birimleri"" bölümüne gidin.'");
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure ThereAreAccrualsForPeriod(TermsAndConditionsAttributes, Cancel)
	
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	SetPrivilegedMode(True);
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.CustomerRebatesAccrualPeriods");
		LockItem.SetValue("TermDocument", TermDocument);
		LockItem.SetValue("Currency", Currency);
		If TermsAndConditionsAttributes.PartyCountDetails = ShouldDetailCalculation.ByCounterparty Then
			
			LockItem.SetValue("Counterparty", Counterparty);
			
		ElsIf TermsAndConditionsAttributes.PartyCountDetails = ShouldDetailCalculation.ByCustomer Then
			
			LockItem.SetValue("Partner", Partner);
			
		Else
			
			LockItem.SetValue("Counterparty", Counterparty);
			LockItem.SetValue("Partner", Partner);
			
		EndIf;
		LockItem.Mode = DataLockMode.Shared;
		Block.Lock();
		
	Except
		
		BeginningOfActionLine = Format(BeginOfPeriod, "DLF=D;");
		EndOfActionWithLine = Format(PeriodEnding, "DLF=D;");
		ErrorTemplate = NStr("vi = 'Không thể kiểm tra đã tính thưởng theo chứng từ điều kiện trong kỳ từ %1 đến %2 do nguyên nhân ""%3"". 
							|Hãy thử lại sau';
							|ru = 'Не удалось выполнить проверку на наличие уже введенных начислений по документу условий за период с %1 по %2 по причине ""%3"". 
							|Попробуйте позже';
							|en = 'Cannot check whether there are already entered accruals in the condition document for the period from %1 to %2 due to ""%3"". 
							|Try again later'; fa = 'Cannot check whether there are already entered accruals in the condition document for the period from %1 to %2 due to ""%3"". 
							|Try again later';
							|it = 'Не удалось выполнить проверку на наличие уже введенных начислений по документу условий за период с %1 по %2 по причине ""%3"". 
							|Попробуйте позже';
							|pl = 'Cannot check whether there are already entered accruals in the condition document for the period from %1 to %2 due to ""%3"". 
							|Try again later';
							|tr = 'Şartlar belgesinde önceden girilmiş olan tahakkuklar, %1 ila %2 aralığında ""%3"" sebebiyle kontrol edilemedi. 
							|Daha sonra tekrar deneyin'");
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate, 
			BeginningOfActionLine,
			EndOfActionWithLine,
			ErrorDescription);
		
		Raise ErrorText;
		
	EndTry;
	
	Selection = SelectionOfAccrualIntersectionsByCondition(TermsAndConditionsAttributes);
	
	While Selection.Next() Do
		
		RecorderPresentation = Selection.RecorderPresentation;
		BeginningOfActionLine = Format(BeginOfPeriod, "DLF=D;");
		EndOfActionWithLine = Format(PeriodEnding, "DLF=D;");
		CurrencyByLine = String(Currency);
		MessageText = "";
		
		If TermsAndConditionsAttributes.PartyCountDetails = ShouldDetailCalculation.ByCounterparty Then
			
			Template = NStr("vi = 'Đã tính thưởng lũy kế theo đối tác và chứng từ điều kiện trong kỳ từ %1 đến %2 theo tiền tệ %3 bằng chứng từ %4';
							|ru = 'По контрагенту и документу условий за период с %1 по %2 в валюте %3 уже выполнено начисление ретро-бонусов документом %4';
							|en = 'There are already accrued rebates based on the %4 document in the %3 currency by the counterparty and condition document for the period from %1 to %2'; fa = 'There are already accrued rebates based on the %4 document in the %3 currency by the counterparty and condition document for the period from %1 to %2';
							|it = 'По контрагенту и документу условий за период с %1 по %2 в валюте %3 уже выполнено начисление ретро-бонусов документом %4';
							|pl = 'There are already accrued rebates based on the %4 document in the %3 currency by the counterparty and condition document for the period from %1 to %2';
							|tr = 'Cari hesap ve %3 para birimindeki %1 ila %2 dönem aralığındaki şartlar belgesi için retro bonusları %4 belgesinde hali hazırda tahakkuk edilmiş'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				BeginningOfActionLine,
				EndOfActionWithLine,
				CurrencyByLine,
				RecorderPresentation);
			
			Common.MessageToUser(MessageText,, "Counterparty", "Object", Cancel);
			
		ElsIf TermsAndConditionsAttributes.PartyCountDetails = ShouldDetailCalculation.ByCustomer Then
			
			Template = NStr("vi = 'Đã tính thưởng lũy kế theo khách hàng và chứng từ điều kiện trong kỳ từ %1 đến %2 theo tiền tệ %3 bằng chứng từ %4';
							|ru = 'По клиенту и документу условий за период с %1 по %2 в валюте %3 уже выполнено начисление ретро-бонусов документом %4';
							|en = 'There are already accrued rebates based on the %4 document in the %3 currency by the customer and condition document for the period from %1 to %2'; fa = 'There are already accrued rebates based on the %4 document in the %3 currency by the customer and condition document for the period from %1 to %2';
							|it = 'По клиенту и документу условий за период с %1 по %2 в валюте %3 уже выполнено начисление ретро-бонусов документом %4';
							|pl = 'There are already accrued rebates based on the %4 document in the %3 currency by the customer and condition document for the period from %1 to %2';
							|tr = 'Cari hesap ve %3 para birimindeki %1 ila %2 dönem aralığındaki şartlar belgesi için retro bonusları %4 belgesinde hali hazırda tahakkuk edilmiş'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				BeginningOfActionLine,
				EndOfActionWithLine,
				CurrencyByLine,
				RecorderPresentation);
			
			Common.MessageToUser(MessageText,, "Partner", "Object", Cancel);
			
		Else
			
			Template = NStr("vi = 'Đã tính thưởng lũy kế theo đối tác, khách hàng và chứng từ điều kiện trong kỳ từ %1 đến %2 theo tiền tệ %3 bằng chứng từ %4';
							|ru = 'По контрагенту, клиенту и документу условий за период с %1 по %2 в валюте %3 уже выполнено начисление ретро-бонусов документом %4';
							|en = 'There are already accrued rebates based on the %4 document in the %3 currency by the counterparty, customer, and condition document for the period from %1 to %2'; fa = 'There are already accrued rebates based on the %4 document in the %3 currency by the counterparty, customer, and condition document for the period from %1 to %2';
							|it = 'По контрагенту, клиенту и документу условий за период с %1 по %2 в валюте %3 уже выполнено начисление ретро-бонусов документом %4';
							|pl = 'There are already accrued rebates based on the %4 document in the %3 currency by the counterparty, customer, and condition document for the period from %1 to %2';
							|tr = 'Cari hesap ve %3 para birimindeki %1 ila %2 dönem aralığındaki şartlar belgesi için retro bonusları %4 belgesinde hali hazırda tahakkuk edilmiş'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				BeginningOfActionLine,
				EndOfActionWithLine,
				CurrencyByLine,
				RecorderPresentation);
			
			Common.MessageToUser(MessageText,, "Counterparty", "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  TermsAndConditionsAttributes - See Documents.ConditionsOfCustomerRebates.UpToDateData
//
// Returns:
//  QueryResultSelection - QueryResultSelection:
// 	* RecorderPresentation - String - presentation of the document
//
Function SelectionOfAccrualIntersectionsByCondition(TermsAndConditionsAttributes)
	
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	Query = New Query;
	Query.SetParameter("Recorder", Ref);
	Query.SetParameter("TermDocument", TermDocument);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	
	QueryText = 
	"SELECT DISTINCT
	|	PRESENTATION(CustomerRebatesAccrualPeriods.Recorder) AS RecorderPresentation
	|FROM
	|	InformationRegister.CustomerRebatesAccrualPeriods AS CustomerRebatesAccrualPeriods
	|WHERE
	|	CustomerRebatesAccrualPeriods.Recorder <> &Recorder
	|	AND CustomerRebatesAccrualPeriods.TermDocument = &TermDocument
	|	AND CustomerRebatesAccrualPeriods.Currency = &Currency
	|	AND (&BeginOfPeriod BETWEEN CustomerRebatesAccrualPeriods.BeginOfPeriod AND CustomerRebatesAccrualPeriods.PeriodEnding
	|			OR &PeriodEnding BETWEEN CustomerRebatesAccrualPeriods.BeginOfPeriod AND CustomerRebatesAccrualPeriods.PeriodEnding
	|			OR &BeginOfPeriod <= CustomerRebatesAccrualPeriods.BeginOfPeriod
	|				AND &PeriodEnding >= CustomerRebatesAccrualPeriods.BeginOfPeriod
	|			OR &BeginOfPeriod <= CustomerRebatesAccrualPeriods.PeriodEnding
	|				AND &PeriodEnding >= CustomerRebatesAccrualPeriods.PeriodEnding)
	|	AND &AdditionalCondition";
	
	AdditionalCondition = "TRUE";
	If TermsAndConditionsAttributes.PartyCountDetails = ShouldDetailCalculation.ByCounterparty Then
		
		Query.SetParameter("Counterparty", Counterparty);
		AdditionalCondition = "CustomerRebatesAccrualPeriods.Counterparty = &Counterparty";
		
	ElsIf TermsAndConditionsAttributes.PartyCountDetails = ShouldDetailCalculation.ByCustomer Then
		
		Query.SetParameter("Partner", Partner);
		AdditionalCondition = "CustomerRebatesAccrualPeriods.Partner = &Partner";
		
	Else
		
		Query.SetParameter("Counterparty", Counterparty);
		Query.SetParameter("Partner", Partner);
		AdditionalCondition = "CustomerRebatesAccrualPeriods.Counterparty = &Counterparty AND CustomerRebatesAccrualPeriods.Partner = &Partner";
		
	EndIf;
	QueryText = StrReplace(QueryText, "&AdditionalCondition", AdditionalCondition);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
	
EndFunction

// Parameters:
//  TermsAndConditionsAttributes - See Documents.ConditionsOfCustomerRebates.UpToDateData
//  Cancel - Boolean
//
Procedure CheckParticipantsAccordingToConditionOfRebates(TermsAndConditionsAttributes, Cancel)
	
	PartyList = TermsAndConditionsAttributes.PartyList;
	Attendees = TermsAndConditionsAttributes.Attendees;
	
	If Attendees <> Enums.RebatesLists.All Then
		
		If PartyList = Enums.RebatesParticipants.TIN Then
			
			CheckParticipantsAccordingToConditionOfINNRebates(TermsAndConditionsAttributes, Cancel);
			
		Else
			
			ToCheckParticipantsAccordingToConditionOfRebatesToCounterpartyClient(TermsAndConditionsAttributes, Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckParticipantsAccordingToConditionOfINNRebates(TermsAndConditionsAttributes, Cancel)
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	PartyCountDetails = TermsAndConditionsAttributes.PartyCountDetails;
	
	ErrorSampling = SelectionOfNonParticipantsByINN(TermsAndConditionsAttributes);
	
	While ErrorSampling.Next() Do
		
		CurrentCounterparty = ErrorSampling.Counterparty;
		CurrentCounterpartyByLine = String(CurrentCounterparty);
		
		If PartyCountDetails = Detailing.ByCustomer Then
			
			If ErrorSampling.INNNotFilledIn Then
				
				Template = NStr("vi = 'Đối tác %1 tại dòng %2 chưa chỉ định MST, không thể kiểm tra tính thưởng';
								|ru = 'У контрагента %1 в строке %2 не указан ИНН, проверка начисления невозможна';
								|en = 'TIN of the %1 counterparty in line %2 is not specified. Cannot check the accrual'; fa = 'TIN of the %1 counterparty in line %2 is not specified. Cannot check the accrual';
								|it = 'У контрагента %1 в строке %2 не указан ИНН, проверка начисления невозможна';
								|pl = 'TIN of the %1 counterparty in line %2 is not specified. Cannot check the accrual';
								|tr = '%2satırındaki %1 cari hesabında VKN belirtilmemiş, tahakkuk mümkün değildir'");
				
			Else
				
				Template = NStr("vi = 'Chứng từ điều kiện không có hiệu lực với đối tác %1 tại dòng %2';
								|ru = 'Документ условий не действует для контрагента %1 в строке %2';
								|en = 'The condition document is not valid for the %1 counterparty in line %2'; fa = 'The condition document is not valid for the %1 counterparty in line %2';
								|it = 'Документ условий не действует для контрагента %1 в строке %2';
								|pl = 'The condition document is not valid for the %1 counterparty in line %2';
								|tr = 'Koşullar belgesi %2 satırındaki %1 cari hesabı için aktif değil'");
				
			EndIf;
			
			LineNumber = ErrorSampling.LineNumber;
			NumAsString = Format(LineNumber, "NG=;");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				CurrentCounterpartyByLine,
				NumAsString);
			
			Field = CommonClientServer.PathToTabularSection("Accruals", LineNumber, "LineNumber");
			Common.MessageToUser(ErrorText,, Field, "Object", Cancel);
			
		Else
			
			If ErrorSampling.INNNotFilledIn Then
				
				Template = NStr("vi = 'Chưa chỉ định MST cho đối tác %1, không thể kiểm tra';
								|ru = 'У контрагента %1 не указан ИНН, проверка начисления невозможна';
								|en = 'TIN of the %1 counterparty is not specified. Cannot check the accrual'; fa = 'TIN of the %1 counterparty is not specified. Cannot check the accrual';
								|it = 'У контрагента %1 не указан ИНН, проверка начисления невозможна';
								|pl = 'TIN of the %1 counterparty is not specified. Cannot check the accrual';
								|tr = '%1 cari hesabında VKN belirtilmemiş, tahakkuk mümkün değildir'");
				
			Else
				
				Template = NStr("vi = 'Chứng từ điều kiện không có hiệu lực đối với đối tác %1';
								|ru = 'Документ условий не действует для контрагента %1';
								|en = 'The condition document is not valid for the %1 counterparty'; fa = 'The condition document is not valid for the %1 counterparty';
								|it = 'Документ условий не действует для контрагента %1';
								|pl = 'The condition document is not valid for the %1 counterparty';
								|tr = 'Koşullar belgesi %1 cari hesabı için aktif değil'");
				
			EndIf;
				
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				Template, 
				CurrentCounterpartyByLine);
				
			Common.MessageToUser(ErrorText,, "Counterparty", "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ToCheckParticipantsAccordingToConditionOfRebatesToCounterpartyClient(TermsAndConditionsAttributes, Cancel)
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	PartyCountDetails = TermsAndConditionsAttributes.PartyCountDetails;
	PartyList = TermsAndConditionsAttributes.PartyList;
	
	FillingErrors = New Structure;
	FillingErrors.Insert("ErrorFillingInHeader", False);
	FillingErrors.Insert("LineFillingErrors", New ValueTable);
	
	If PartyList = Enums.RebatesParticipants.Counterparties Then
		
		FillingErrors = TheseAreNotCounterpartyParticipants(TermsAndConditionsAttributes);
		
	ElsIf PartyList = Enums.RebatesParticipants.Customers
	 Or PartyList = Enums.RebatesParticipants.PartnersSegments Then
		
		FillingErrors = DataIsNotParticipantsCustomers(TermsAndConditionsAttributes);
		
	ElsIf PartyList = Enums.RebatesParticipants.Contracts Then
		
		FillingErrors = TheseAreNotParticipantsInContracts(TermsAndConditionsAttributes);
		
	ElsIf PartyList = Enums.RebatesParticipants.Terms1 Then
		
		FillingErrors = DataAreNotParticipantsInAgreements(TermsAndConditionsAttributes);
		
	EndIf;
	
	CounterpartyByLine = String(Counterparty);
	PartnerByLine = String(Partner);
		
	If FillingErrors.ErrorFillingInHeader Then
		
		If PartyCountDetails = Detailing.ByCounterpartyAndCustomer Then
			
			Template = NStr("vi = 'Chứng từ điều kiện không có hiệu lực với đối tác %1 và khách hàng %2';
							|ru = 'Документ условий не действует для контрагента %1 и клиента %2';
							|en = 'The condition document is not valid for the %1 counterparty and the %2 customer'; fa = 'The condition document is not valid for the %1 counterparty and the %2 customer';
							|it = 'Документ условий не действует для контрагента %1 и клиента %2';
							|pl = 'The condition document is not valid for the %1 counterparty and the %2 customer';
							|tr = 'Koşullar belgesi %1 cari hesabı ve %2 müşterisi için aktif değil'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				Template, 
				CounterpartyByLine,
				PartnerByLine);
			
			If PartyList = Enums.RebatesParticipants.Terms1
			 Or PartyList = Enums.RebatesParticipants.PartnersSegments Then
				Common.MessageToUser(ErrorText,, "Partner", "Object", Cancel);
			Else
				Common.MessageToUser(ErrorText,, "Counterparty", "Object", Cancel);
			EndIf;
			
		ElsIf PartyCountDetails = Detailing.ByCounterparty Then
			
			Template = NStr("vi = 'Chứng từ điều kiện không có hiệu lực đối với đối tác %1';
							|ru = 'Документ условий не действует для контрагента %1';
							|en = 'The condition document is not valid for the %1 counterparty'; fa = 'The condition document is not valid for the %1 counterparty';
							|it = 'Документ условий не действует для контрагента %1';
							|pl = 'The condition document is not valid for the %1 counterparty';
							|tr = 'Koşullar belgesi %1 cari hesabı için aktif değil'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				CounterpartyByLine);
			
			Common.MessageToUser(ErrorText,, "Counterparty", "Object", Cancel);
			
		Else
			
			Template = NStr("vi = 'Chứng từ điều kiện không có hiệu lực đối với khách hàng %1';
							|ru = 'Документ условий не действует для клиента %1';
							|en = 'The condition document is not valid for the %1 customer'; fa = 'The condition document is not valid for the %1 customer';
							|it = 'Документ условий не действует для клиента %1';
							|pl = 'The condition document is not valid for the %1 customer';
							|tr = 'Koşullar belgesi %1 müşterisi için aktif değil'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				PartnerByLine);
			
			Common.MessageToUser(ErrorText,, "Partner", "Object", Cancel);
			
		EndIf;
		
	Else
		
		For Each CurrentLineError In FillingErrors.LineFillingErrors Do
			
			LineNumber = CurrentLineError.LineNumber;
			NumAsString = String(LineNumber);
			
			If PartyCountDetails = Detailing.ByCounterparty Then
			
				CurPartner = CurrentLineError.Partner;
				CurrentPartnerByLine = String(CurPartner);
				
				Template = NStr("vi = 'Chứng từ điều kiện không có hiệu lực đối với đối tác %1 và khách hàng %2 tại dòng %3';
								|ru = 'Документ условий не действует для контрагента %1 и клиента %2 в строке %3';
								|en = 'The condition document is not valid for the %1 counterparty and the %2 customer in line %3'; fa = 'The condition document is not valid for the %1 counterparty and the %2 customer in line %3';
								|it = 'Документ условий не действует для контрагента %1 и клиента %2 в строке %3';
								|pl = 'The condition document is not valid for the %1 counterparty and the %2 customer in line %3';
								|tr = 'Koşullar belgesi %1 cari hesabı için ve %3 satırındaki %2 müşterisi için aktif değil'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					Template,
					CounterpartyByLine,
					CurrentPartnerByLine,
					NumAsString);
					
			Else
				
				CurrentCounterparty = CurrentLineError.Counterparty;
				CurrentCounterpartyByLine = String(CurrentCounterparty);
				
				Template = NStr("vi = 'Chứng từ điều kiện không có hiệu lực đối với khách hàng %1 và đối tác %2 tại dòng %3';
								|ru = 'Документ условий не действует для клиента %1 и контрагента %2 в строке %3';
								|en = 'The condition document is not valid for the %1 customer and the %2 counterparty in line %3'; fa = 'The condition document is not valid for the %1 customer and the %2 counterparty in line %3';
								|it = 'Документ условий не действует для клиента %1 и контрагента %2 в строке %3';
								|pl = 'The condition document is not valid for the %1 customer and the %2 counterparty in line %3';
								|tr = 'Koşullar belgesi %1 müşterisi için ve %3 satırındaki %2 cari hesabı için aktif değil'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					Template,
					PartnerByLine,
					CurrentCounterpartyByLine,
					NumAsString);
				
			EndIf;
			
			Field = CommonClientServer.PathToTabularSection("Accruals", LineNumber, "LineNumber");
			Common.MessageToUser(ErrorText,, Field, "Object", Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Parameters:
//  TermsAndConditionsAttributes - See Documents.ConditionsOfCustomerRebates.UpToDateData
// 
// Returns:
//  QueryResultSelection:
//  * INNNotFilledIn - Boolean
//  * Counterparty - CatalogRef.Counterparties
//  * LineNumber - Number
//
Function SelectionOfNonParticipantsByINN(TermsAndConditionsAttributes)
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	PartyCountDetails = TermsAndConditionsAttributes.PartyCountDetails;
	
	If PartyCountDetails <> Detailing.ByCustomer Then
		
		TableOfParticipants = New ValueTable;
		TableOfParticipants.Columns.Add("LineNumber", New TypeDescription("Number"));
		TableOfParticipants.Columns.Add("Counterparty", New TypeDescription("CatalogRef.Counterparties"));
		
		NewRow = TableOfParticipants.Add();
		NewRow.Counterparty = Counterparty;
		NewRow.LineNumber = 0;
		
	Else
		
		TableOfParticipants = Accruals.Unload(, "LineNumber, Counterparty");
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("TableOfParticipants", TableOfParticipants);
	Query.SetParameter("TermDocument", TermDocument);
	Query.SetParameter("Attendees", TermsAndConditionsAttributes.Attendees);
	
	QueryText =
	"SELECT
	|	TableOfParticipants.Counterparty AS Counterparty,
	|	TableOfParticipants.LineNumber AS LineNumber
	|INTO TT_Counterparties
	|FROM
	|	&TableOfParticipants AS TableOfParticipants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TT_Counterparties.Counterparty AS Counterparty,
	|	TT_Counterparties.LineNumber,
	|	ISNULL(Counterparties.TIN, """") AS TIN
	|INTO VT_CounterpartiesTIN
	|FROM
	|	TT_Counterparties AS TT_Counterparties
	|		LEFT JOIN Catalog.Counterparties AS Counterparties
	|		ON TT_Counterparties.Counterparty = Counterparties.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALSE AS INNNotFilledIn,
	|	VT_CounterpartiesTIN.Counterparty,
	|	VT_CounterpartiesTIN.LineNumber AS LineNumber
	|FROM
	|	VT_CounterpartiesTIN AS VT_CounterpartiesTIN
	|		LEFT JOIN InformationRegister.CustomerRebatesTIN AS CustomerRebatesTIN
	|		ON VT_CounterpartiesTIN.TIN = CustomerRebatesTIN.TIN
	|		AND CustomerRebatesTIN.TermDocument = &TermDocument
	|WHERE
	|	&Attendees = VALUE(Enum.RebatesLists.Selected_)
	|GROUP BY
	|	VT_CounterpartiesTIN.Counterparty,
	|	VT_CounterpartiesTIN.LineNumber
	|HAVING
	|	MIN(CASE
	|		WHEN CustomerRebatesTIN.TIN IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END) = TRUE
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE,
	|	VT_CounterpartiesTIN.Counterparty,
	|	VT_CounterpartiesTIN.LineNumber
	|FROM
	|	VT_CounterpartiesTIN AS VT_CounterpartiesTIN
	|		LEFT JOIN InformationRegister.CustomerRebatesTIN AS CustomerRebatesTIN
	|		ON VT_CounterpartiesTIN.TIN = CustomerRebatesTIN.TIN
	|		AND CustomerRebatesTIN.TermDocument = &TermDocument
	|WHERE
	|	&Attendees = VALUE(Enum.RebatesLists.ExceptForSelectedOnes)
	|	AND VT_CounterpartiesTIN.TIN <> """"
	|GROUP BY
	|	VT_CounterpartiesTIN.Counterparty,
	|	VT_CounterpartiesTIN.LineNumber
	|HAVING
	|	MAX(CASE
	|		WHEN NOT CustomerRebatesTIN.TIN IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END) = TRUE
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE,
	|	VT_CounterpartiesTIN.Counterparty,
	|	VT_CounterpartiesTIN.LineNumber
	|FROM
	|	VT_CounterpartiesTIN AS VT_CounterpartiesTIN
	|WHERE
	|	&Attendees = VALUE(Enum.RebatesLists.ExceptForSelectedOnes)
	|	AND VT_CounterpartiesTIN.TIN = """"
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
	
EndFunction

// Parameters:
//  TermsAndConditionsAttributes - See Documents.ConditionsOfCustomerRebates.UpToDateData
//
// Returns:
//  Structure:
//  * ErrorFillingInHeader - Boolean
//  * LineFillingErrors - ValueTable:
//   ** LineNumber - Number
//   ** Counterparty - CatalogRef.Counterparties
//   ** Partner - CatalogRef.Partners
//
Function TheseAreNotCounterpartyParticipants(TermsAndConditionsAttributes)
	
	FillingErrors = New Structure;
	FillingErrors.Insert("ErrorFillingInHeader", False);
	FillingErrors.Insert("LineFillingErrors", New ValueTable);
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	PartyCountDetails = TermsAndConditionsAttributes.PartyCountDetails;
	ListCompositions = Enums.RebatesLists;
	Attendees = TermsAndConditionsAttributes.Attendees;
	ErrorFillingInHeader = False;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("TermDocument", TermDocument);
	
	If PartyCountDetails = Detailing.ByCustomer Then
		
		Query.SetParameter("Partner", Partner);
		QueryText = 
		"SELECT
		|	CustomerRebatesCounterparties.Counterparty
		|INTO TT_Attendees
		|FROM
		|	InformationRegister.CustomerRebatesCounterparties AS CustomerRebatesCounterparties
		|WHERE
		|	(CustomerRebatesCounterparties.Partner = &Partner
		|	OR CustomerRebatesCounterparties.Partner = VALUE(Catalog.Partners.EmptyRef))
		|	AND CustomerRebatesCounterparties.TermDocument = &TermDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_Attendees.Counterparty
		|FROM
		|	TT_Attendees AS TT_Attendees";
		
	ElsIf PartyCountDetails = Detailing.ByCounterparty Then
		
		Query.SetParameter("Counterparty", Counterparty);
		QueryText = 
		"SELECT
		|	CustomerRebatesCounterparties.Partner
		|INTO TT_Attendees
		|FROM
		|	InformationRegister.CustomerRebatesCounterparties AS CustomerRebatesCounterparties
		|WHERE
		|	CustomerRebatesCounterparties.Counterparty = &Counterparty
		|	AND CustomerRebatesCounterparties.TermDocument = &TermDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_Attendees.Partner
		|FROM
		|	TT_Attendees AS TT_Attendees";
		
	Else
		
		Query.SetParameter("Partner", Partner);
		Query.SetParameter("Counterparty", Counterparty);
		QueryText = 
		"SELECT
		|	CustomerRebatesCounterparties.Partner
		|FROM
		|	InformationRegister.CustomerRebatesCounterparties AS CustomerRebatesCounterparties
		|WHERE
		|	(CustomerRebatesCounterparties.Partner = &Partner
		|	OR CustomerRebatesCounterparties.Partner = VALUE(Catalog.Partners.EmptyRef))
		|	AND CustomerRebatesCounterparties.Counterparty = &Counterparty
		|	AND CustomerRebatesCounterparties.TermDocument = &TermDocument";
		
	EndIf;
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Attendees = ListCompositions.Selected_
	   And Result.IsEmpty() Then
		
		ErrorFillingInHeader = True;
		
	ElsIf Attendees = ListCompositions.ExceptForSelectedOnes
	   And PartyCountDetails = Detailing.ByCounterpartyAndCustomer
	   And Not Result.IsEmpty() Then
		
		ErrorFillingInHeader = True;
		
	EndIf;
	
	If PartyCountDetails <> Detailing.ByCounterpartyAndCustomer
	   And Not ErrorFillingInHeader Then
		
		ResultTable2 = Result.Unload();
		
		If PartyCountDetails = Detailing.ByCounterparty Then
			
			If ResultTable2.Find(Catalogs.Partners.EmptyRef(), "Partner") = Undefined Then
				
				TableOfParticipants = Accruals.Unload(, "LineNumber, Partner");
				
				Query.SetParameter("TableOfParticipants", TableOfParticipants);
				Query.SetParameter("ResultTable2", ResultTable2);
				Query.SetParameter("Attendees", Attendees);
				
				Query.Text = QueryTextStringProcessing();
				FillingErrors.Insert("LineFillingErrors", Query.Execute().Unload());
				
			Else
				
				If Attendees = ListCompositions.ExceptForSelectedOnes Then
					ErrorFillingInHeader = True;
				EndIf;
				
			EndIf;
			
		Else
			
			TableOfParticipants = Accruals.Unload(, "LineNumber, Counterparty, Partner");
			
			Query.SetParameter("TableOfParticipants", TableOfParticipants);
			Query.SetParameter("ResultTable2", ResultTable2);
			Query.SetParameter("Attendees", Attendees);
			
			Query.Text = QueryTextStringProcessing(True);
			FillingErrors.Insert("LineFillingErrors", Query.Execute().Unload());
			
		EndIf;
		
	EndIf;
	
	FillingErrors.Insert("ErrorFillingInHeader", ErrorFillingInHeader);
	
	Return FillingErrors;
	
EndFunction

// Parameters:
//  TermsAndConditionsAttributes - See Documents.ConditionsOfCustomerRebates.UpToDateData
//
// Returns:
//  Structure:
//  * ErrorFillingInHeader - Boolean
//  * LineFillingErrors - ValueTable:
//   ** LineNumber - Number
//   ** Counterparty - CatalogRef.Counterparties
//   ** Partner - CatalogRef.Partners
//
Function DataIsNotParticipantsCustomers( TermsAndConditionsAttributes)
	
	FillingErrors = New Structure;
	FillingErrors.Insert("ErrorFillingInHeader", False);
	FillingErrors.Insert("LineFillingErrors", New ValueTable);
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	PartyCountDetails = TermsAndConditionsAttributes.PartyCountDetails;
	ListCompositions = Enums.RebatesLists;
	Attendees = TermsAndConditionsAttributes.Attendees;
	ErrorFillingInHeader = False;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("TermDocument", TermDocument);
	
	If PartyCountDetails = Detailing.ByCustomer Then
		
		Query.SetParameter("Partner", Partner);
		QueryText = 
		"SELECT
		|	CustomerRebatesCounterparties.Counterparty
		|INTO TT_Attendees
		|FROM
		|	InformationRegister.CustomerRebatesCounterparties AS CustomerRebatesCounterparties
		|WHERE
		|	CustomerRebatesCounterparties.Partner = &Partner
		|	AND CustomerRebatesCounterparties.TermDocument = &TermDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_Attendees.Counterparty
		|FROM
		|	TT_Attendees AS TT_Attendees";
		
	ElsIf PartyCountDetails = Detailing.ByCounterparty Then
		
		Query.SetParameter("Counterparty", Counterparty);
		QueryText = 
		"SELECT
		|	CustomerRebatesCounterparties.Partner
		|INTO TT_Attendees
		|FROM
		|	InformationRegister.CustomerRebatesCounterparties AS CustomerRebatesCounterparties
		|WHERE
		|	(CustomerRebatesCounterparties.Counterparty = &Counterparty
		|	OR CustomerRebatesCounterparties.Counterparty = VALUE(Catalog.Counterparties.EmptyRef))
		|	AND CustomerRebatesCounterparties.TermDocument = &TermDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_Attendees.Partner
		|FROM
		|	TT_Attendees AS TT_Attendees";
		
	Else
		
		Query.SetParameter("Partner", Partner);
		Query.SetParameter("Counterparty", Counterparty);
		QueryText = 
		"SELECT
		|	CustomerRebatesCounterparties.Partner
		|FROM
		|	InformationRegister.CustomerRebatesCounterparties AS CustomerRebatesCounterparties
		|WHERE
		|	CustomerRebatesCounterparties.Partner = &Partner
		|	AND (CustomerRebatesCounterparties.Counterparty = &Counterparty
		|	OR CustomerRebatesCounterparties.Counterparty = VALUE(Catalog.Counterparties.EmptyRef))
		|	AND CustomerRebatesCounterparties.TermDocument = &TermDocument";
		
	EndIf;
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Attendees = ListCompositions.Selected_
	   And Result.IsEmpty() Then
		
		ErrorFillingInHeader = True;
		
	ElsIf Attendees = ListCompositions.ExceptForSelectedOnes
	   And PartyCountDetails = Detailing.ByCounterpartyAndCustomer
	   And Not Result.IsEmpty() Then
		
		ErrorFillingInHeader = True;
		
	EndIf;
	
	If PartyCountDetails <> Detailing.ByCounterpartyAndCustomer
	   And Not ErrorFillingInHeader Then
		
		If PartyCountDetails = Detailing.ByCounterparty Then
			
			TableOfParticipants = Accruals.Unload(, "LineNumber, Partner");
			
			Query.SetParameter("TableOfParticipants", TableOfParticipants);
			Query.SetParameter("Attendees", Attendees);
			Query.Text = QueryTextStringProcessing();
			FillingErrors.Insert("LineFillingErrors", Query.Execute().Unload());
			
		Else
			
			ResultTable2 = Result.Unload();
			If ResultTable2.Find(Catalogs.Counterparties.EmptyRef(), "Counterparty") = Undefined Then
				
				TableOfParticipants = Accruals.Unload(, "LineNumber, Counterparty");
				
				Query.SetParameter("TableOfParticipants", TableOfParticipants);
				Query.SetParameter("ResultTable2", ResultTable2);
				Query.SetParameter("Attendees", Attendees);
				
				Query.Text = QueryTextStringProcessing(True);
				FillingErrors.Insert("LineFillingErrors", Query.Execute().Unload());
				
			Else
				
				If Attendees = ListCompositions.ExceptForSelectedOnes Then
					ErrorFillingInHeader = True;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	FillingErrors.Insert("ErrorFillingInHeader", ErrorFillingInHeader);
	
	Return FillingErrors;
	
EndFunction

// Parameters:
//  TermsAndConditionsAttributes - See Documents.ConditionsOfCustomerRebates.UpToDateData
//
// Returns:
//  Structure:
//  * ErrorFillingInHeader - Boolean
//  * LineFillingErrors - ValueTable:
//   ** LineNumber - Number
//   ** Counterparty - CatalogRef.Counterparties
//   ** Partner - CatalogRef.Partners
//
Function DataAreNotParticipantsInAgreements(TermsAndConditionsAttributes)
	
	FillingErrors = New Structure;
	FillingErrors.Insert("ErrorFillingInHeader", False);
	FillingErrors.Insert("LineFillingErrors", New ValueTable);
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	PartyCountDetails = TermsAndConditionsAttributes.PartyCountDetails;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("TermDocument", TermDocument);
	
	QueryText = 
	"SELECT DISTINCT
	|	TermsOfSale.Partner AS Partner,
	|	TermsOfSale.Counterparty AS Counterparty,
	|	TermsOfSale.Standard_ AS Standard_
	|INTO TT_CounterpartyPartners
	|FROM
	|	InformationRegister.CustomerRebatesContractsTermsOfSales AS CustomerRebatesContractsTermsOfSales
	|		INNER JOIN Catalog.TermsOfSale AS TermsOfSale
	|		ON CustomerRebatesContractsTermsOfSales.Terms = TermsOfSale.Ref
	|		AND CustomerRebatesContractsTermsOfSales.TermDocument = &TermDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(TT_CounterpartyPartners.Standard_) AS Standard_
	|FROM
	|	TT_CounterpartyPartners AS TT_CounterpartyPartners
	|HAVING
	|	MAX(TT_CounterpartyPartners.Standard_) = TRUE";
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		
		If PartyCountDetails = Detailing.ByCustomer Then
			
			DataIsNotParticipantsByAgreementDetailsByClient(Query, FillingErrors);
			
		ElsIf PartyCountDetails = Detailing.ByCounterparty Then
			
			DataIsNotParticipantsByAgreementDetailsByCounterparty(Query, FillingErrors);
			
		Else
			
			DataAreNotParticipantsInAgreementsDetailsByClientByCounterparty(Query, FillingErrors);
			
		EndIf;
		
	EndIf;
	
	Return FillingErrors;
	
EndFunction

// Parameters:
//  Query - Query - Query
//  FillingErrors - Structure - Fill-in errors:
// * ErrorFillingInHeader - Boolean
// * LineFillingErrors - ValueTable
//
Procedure DataAreNotParticipantsInAgreementsDetailsByClientByCounterparty(Query, FillingErrors)
	
	ErrorFillingInHeader = False;
	
	ArrayOfCounterparties = New Array;  // Array of CatalogRef.Counterparties
	ArrayOfCounterparties.Add(Counterparty);
	ArrayOfCounterparties.Add(Catalogs.Counterparties.EmptyRef());
	
	Query.SetParameter("Counterparties", ArrayOfCounterparties);
	Query.SetParameter("Partner", Partner);
	
	QueryText = 
	"SELECT
	|	TT_CounterpartyPartners.Partner AS Partner
	|
	|FROM
	|	TT_CounterpartyPartners AS TT_CounterpartyPartners
	|WHERE
	|	TT_CounterpartyPartners.Counterparty IN (&Counterparties)
	|	AND TT_CounterpartyPartners.Partner = &Partner";
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		
		ErrorFillingInHeader = True;
		
	EndIf;
	
	FillingErrors.ErrorFillingInHeader = ErrorFillingInHeader;
	
EndProcedure

// Parameters:
//  Query - Query - Query
//  FillingErrors - Structure - Fill-in errors:
// * ErrorFillingInHeader - Boolean
// * LineFillingErrors - ValueTable
//
Procedure DataIsNotParticipantsByAgreementDetailsByCounterparty(Query, FillingErrors)
	
	ErrorFillingInHeader = False;
	SelectedParticipants = Enums.RebatesLists.Selected_;
	
	ArrayOfCounterparties = New Array;  // Array of CatalogRef.Counterparties
	ArrayOfCounterparties.Add(Counterparty);
	ArrayOfCounterparties.Add(Catalogs.Counterparties.EmptyRef());
	
	Query.SetParameter("Counterparties", ArrayOfCounterparties);
	
	QueryText = 
	"SELECT
	|	TT_CounterpartyPartners.Partner AS Partner
	|INTO TT_Attendees
	|FROM
	|	TT_CounterpartyPartners AS TT_CounterpartyPartners
	|WHERE
	|	TT_CounterpartyPartners.Counterparty IN (&Counterparties)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Attendees.Partner AS Partner
	|FROM
	|	TT_Attendees AS TT_Attendees";
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		
		ErrorFillingInHeader = True;
		
	Else
		
		TableOfParticipants = Accruals.Unload(, "LineNumber, Partner");
		
		Query.SetParameter("TableOfParticipants", TableOfParticipants);
		Query.SetParameter("Attendees", SelectedParticipants);
		Query.Text = QueryTextStringProcessing();
		FillingErrors.LineFillingErrors = Query.Execute().Unload();
		
	EndIf;
	
	FillingErrors.ErrorFillingInHeader = ErrorFillingInHeader;
	
EndProcedure

// Parameters:
//  Query - Query - Query
//  FillingErrors - Structure - Fill-in errors:
// * ErrorFillingInHeader - Boolean
// * LineFillingErrors - ValueTable
//
Procedure DataIsNotParticipantsByAgreementDetailsByClient(Query, FillingErrors)
	
	ErrorFillingInHeader = False;
	SelectedParticipants = Enums.RebatesLists.Selected_;
	
	Query.SetParameter("Partner", Partner);
	
	QueryText = 
	"SELECT
	|	TT_CounterpartyPartners.Counterparty AS Counterparty
	|INTO TT_Attendees
	|FROM
	|	TT_CounterpartyPartners AS TT_CounterpartyPartners
	|WHERE
	|	TT_CounterpartyPartners.Partner = &Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Attendees.Counterparty AS Counterparty
	|FROM
	|	TT_Attendees AS TT_Attendees";
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		
		ErrorFillingInHeader = True;
		
	Else
		
		ResultTable2 = Result.Unload();
		If ResultTable2.Find(Catalogs.Counterparties.EmptyRef(), "Counterparty") = Undefined Then
			
			TableOfParticipants = Accruals.Unload(, "LineNumber, Counterparty");
			
			Query.SetParameter("TableOfParticipants", TableOfParticipants);
			Query.SetParameter("ResultTable2", ResultTable2);
			Query.SetParameter("Attendees", SelectedParticipants);
			
			Query.Text = QueryTextStringProcessing(True);
			FillingErrors.LineFillingErrors =  Query.Execute().Unload();
			
		EndIf;
		
	EndIf;
	
	FillingErrors.ErrorFillingInHeader = ErrorFillingInHeader;
	
EndProcedure

// Parameters:
//  TermsAndConditionsAttributes - See Documents.ConditionsOfCustomerRebates.UpToDateData
//
// Returns:
//  Structure:
//  * ErrorFillingInHeader - Boolean
//  * LineFillingErrors - ValueTable:
//   ** LineNumber - Number
//   ** Counterparty - CatalogRef.Counterparties
//   ** Partner - CatalogRef.Partners
//
Function TheseAreNotParticipantsInContracts(TermsAndConditionsAttributes)
	
	FillingErrors = New Structure;
	FillingErrors.Insert("ErrorFillingInHeader", False);
	FillingErrors.Insert("LineFillingErrors", New ValueTable);
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	PartyCountDetails = TermsAndConditionsAttributes.PartyCountDetails;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("TermDocument", TermDocument);
	
	QueriesArray = New Array;  // Array of String
	
	QueryText = 
	"SELECT DISTINCT
	|	CounterpartyContracts.Partner AS Partner,
	|	CounterpartyContracts.Counterparty AS Counterparty,
	|	CounterpartyContracts.ItIsAllowedToWorkWithSubsidiaryPartners AS ItIsAllowedToWorkWithSubsidiaryPartners
	|INTO TT_CounterpartyPartners
	|FROM
	|	InformationRegister.CustomerRebatesContractsTermsOfSales AS CustomerRebatesContractsTermsOfSales
	|		INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON CustomerRebatesContractsTermsOfSales.Contract = CounterpartyContracts.Ref
	|		AND CustomerRebatesContractsTermsOfSales.TermDocument = &TermDocument";
	
	QueriesArray.Add(QueryText);
	
	If PartyCountDetails = Detailing.ByCustomer Then
		
		DataNotParticipantsInContractDetailsForClient(Query, QueriesArray, FillingErrors);
		
	ElsIf PartyCountDetails = Detailing.ByCounterparty Then
		
		DataAreNotParticipantsInContractsDetailsByCounterparty(Query, QueriesArray, FillingErrors);
		
	Else
		
		DataAreNotParticipantsInContractsDetailsByClientByCounterparty(Query, QueriesArray, FillingErrors);
		
	EndIf;
	
	Return FillingErrors;
	
EndFunction

// Parameters:
//  Query - Query - Query
//  QueriesArray - Array of String - Array of requests
//  FillingErrors - Structure - Fill-in errors:
// * ErrorFillingInHeader - Boolean
// * LineFillingErrors - ValueTable
//
Procedure DataAreNotParticipantsInContractsDetailsByClientByCounterparty(Query, QueriesArray, FillingErrors)
	
	ErrorFillingInHeader = False;
	
	PartnerList = New ValueList;
	PartnersAndCounterparties.FillInListOfPartnersWithParents(Partner, PartnerList);
	
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("PartnerList", PartnerList);
	Query.SetParameter("Counterparty", Counterparty);
	
	QueryText = 
	"SELECT
	|	CounterpartyPartners.Counterparty AS Counterparty
	|FROM
	|	TT_CounterpartyPartners AS CounterpartyPartners
	|WHERE
	|	CounterpartyPartners.ItIsAllowedToWorkWithSubsidiaryPartners
	|	AND CounterpartyPartners.Partner IN (&PartnerList)
	|	AND CounterpartyPartners.Counterparty = &Counterparty
	|
	|UNION ALL
	|
	|SELECT
	|	CounterpartyPartners.Counterparty
	|FROM
	|	TT_CounterpartyPartners AS CounterpartyPartners
	|WHERE
	|	NOT CounterpartyPartners.ItIsAllowedToWorkWithSubsidiaryPartners
	|	AND CounterpartyPartners.Partner = &Partner
	|	AND CounterpartyPartners.Counterparty = &Counterparty";
	
	QueriesArray.Add(QueryText);
	
	QueryText = StrConcat(QueriesArray, Common.QueryBatchSeparator());
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		
		ErrorFillingInHeader = True;
		
	EndIf;
	
	FillingErrors.ErrorFillingInHeader =  ErrorFillingInHeader;
	
EndProcedure

// Parameters:
//  Query - Query - Query
//  QueriesArray - Array of String - Array of requests
//  FillingErrors - Structure - Fill-in errors:
// * ErrorFillingInHeader - Boolean
// * LineFillingErrors - ValueTable
//
Procedure DataAreNotParticipantsInContractsDetailsByCounterparty(Query, QueriesArray, FillingErrors)
	
	ErrorFillingInHeader = False;
	
	Query.SetParameter("Counterparty", Counterparty);
	
	QueryText = 
	"SELECT
	|	TT_CounterpartyPartners.Partner AS Partner,
	|	TT_CounterpartyPartners.ItIsAllowedToWorkWithSubsidiaryPartners AS ItIsAllowedToWorkWithSubsidiaryPartners
	|INTO TT_Attendees
	|FROM
	|	TT_CounterpartyPartners AS TT_CounterpartyPartners
	|WHERE
	|	TT_CounterpartyPartners.Counterparty = &Counterparty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Attendees.Partner AS Partner
	|FROM
	|	TT_Attendees AS TT_Attendees";
	
	QueriesArray.Add(QueryText);
	QueryText = StrConcat(QueriesArray, Common.QueryBatchSeparator());
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		
		ErrorFillingInHeader = True;
		
	Else
		
		SetPrivilegedMode(True);
		
		TableOfParticipants = Accruals.Unload(, "LineNumber, Partner");
		Query.SetParameter("TableOfParticipants", TableOfParticipants);
		
		QueryText = QueryTextProcessingPartnerStringsUnderContracts();
		Query.Text = QueryText; 
		
		FillingErrors.LineFillingErrors = Query.Execute().Unload();
		
	EndIf;
	
	FillingErrors.ErrorFillingInHeader =  ErrorFillingInHeader;
	
EndProcedure

// Parameters:
//  Query - Query - Query
//  QueriesArray - Array of String - Array of requests
//  FillingErrors - Structure - Fill-in errors:
// * ErrorFillingInHeader - Boolean
// * LineFillingErrors - ValueTable
//
Procedure DataNotParticipantsInContractDetailsForClient(Query, QueriesArray, FillingErrors)
	
	ErrorFillingInHeader = False;
	
	PartnerList = New ValueList;
	PartnersAndCounterparties.FillInListOfPartnersWithParents(Partner, PartnerList);
	
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("PartnerList", PartnerList);
	
	QueryText =
	"SELECT
	|	CounterpartyPartners.Counterparty AS Counterparty
	|INTO TT_Attendees
	|FROM
	|	TT_CounterpartyPartners AS CounterpartyPartners
	|WHERE
	|	CounterpartyPartners.ItIsAllowedToWorkWithSubsidiaryPartners
	|	AND CounterpartyPartners.Partner IN (&PartnerList)
	|
	|UNION ALL
	|
	|SELECT
	|	CounterpartyPartners.Counterparty
	|FROM
	|	TT_CounterpartyPartners AS CounterpartyPartners
	|WHERE
	|	NOT CounterpartyPartners.ItIsAllowedToWorkWithSubsidiaryPartners
	|	AND CounterpartyPartners.Partner = &Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Attendees.Counterparty AS Counterparty
	|FROM
	|	TT_Attendees AS TT_Attendees";
	
	QueriesArray.Add(QueryText);
	
	QueryText = StrConcat(QueriesArray, Common.QueryBatchSeparator());
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		
		ErrorFillingInHeader = True;
		
	Else
		
		TableOfParticipants = Accruals.Unload(, "LineNumber, Counterparty");
		
		Query.SetParameter("TableOfParticipants", TableOfParticipants);
		Query.SetParameter("Attendees", Enums.RebatesLists.Selected_);
		Query.Text = QueryTextStringProcessing(True);
		FillingErrors.LineFillingErrors = Query.Execute().Unload();
		
	EndIf;
	
	FillingErrors.ErrorFillingInHeader =  ErrorFillingInHeader;
	
EndProcedure

Function QueryTextProcessingPartnerStringsUnderContracts()
	
	QueryText =
	"SELECT
	|	TableOfDocumentParticipants.Partner AS Partner,
	|	TableOfDocumentParticipants.LineNumber AS LineNumber
	|INTO TableOfParticipants
	|FROM
	|	&TableOfParticipants AS TableOfDocumentParticipants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ISNULL(PartnerHierarchy.Parent, VALUE(Catalog.Partners.EmptyRef)) AS Parent,
	|	TableOfParticipants.Partner AS Partner
	|INTO VT_PartnersParents
	|FROM
	|	TableOfParticipants AS TableOfParticipants
	|		LEFT JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|		ON TableOfParticipants.Partner = PartnerHierarchy.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Attendees.Partner AS Partner
	|INTO VT_FoundMembers
	|FROM
	|	TT_Attendees AS TT_Attendees
	|		INNER JOIN TableOfParticipants AS TableOfParticipants
	|		ON TT_Attendees.Partner = TableOfParticipants.Partner
	|WHERE
	|	NOT TT_Attendees.ItIsAllowedToWorkWithSubsidiaryPartners
	|
	|UNION ALL
	|
	|SELECT
	|	VT_PartnersParents.Partner
	|FROM
	|	TT_Attendees AS TT_Attendees
	|		INNER JOIN VT_PartnersParents AS VT_PartnersParents
	|		ON TT_Attendees.Partner = VT_PartnersParents.Parent
	|WHERE
	|	TT_Attendees.ItIsAllowedToWorkWithSubsidiaryPartners
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfParticipants.Partner AS Partner,
	|	TableOfParticipants.LineNumber AS LineNumber
	|FROM
	|	TableOfParticipants AS TableOfParticipants
	|		LEFT JOIN VT_FoundMembers AS VT_FoundMembers
	|		ON TableOfParticipants.Partner = VT_FoundMembers.Partner
	|WHERE
	|	VT_FoundMembers.Partner IS NULL";
	
	Return QueryText;
	
EndFunction

Function QueryTextStringProcessing(DetailsByPartner = False)
	
	QueryText =
	"SELECT
	|	TableOfDocumentParticipants.Partner AS Partner,
	|	TableOfDocumentParticipants.LineNumber AS LineNumber
	|INTO TableOfParticipants
	|FROM
	|	&TableOfParticipants AS TableOfDocumentParticipants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfDocumentParticipants.Partner AS Partner,
	|	TableOfDocumentParticipants.LineNumber AS LineNumber
	|FROM
	|	TableOfParticipants AS TableOfDocumentParticipants
	|		LEFT JOIN TT_Attendees AS TT_Attendees
	|		ON TableOfDocumentParticipants.Partner = TT_Attendees.Partner
	|WHERE
	|	TT_Attendees.Partner IS NULL
	|	AND &Attendees = VALUE(Enum.RebatesLists.Selected_)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfDocumentParticipants.Partner,
	|	TableOfDocumentParticipants.LineNumber
	|FROM
	|	TableOfParticipants AS TableOfDocumentParticipants
	|		LEFT JOIN TT_Attendees AS TT_Attendees
	|		ON TableOfDocumentParticipants.Partner = TT_Attendees.Partner
	|WHERE
	|	NOT TT_Attendees.Partner IS NULL
	|	AND &Attendees = VALUE(Enum.RebatesLists.ExceptForSelectedOnes)
	|
	|ORDER BY
	|	LineNumber";
	
	If DetailsByPartner Then
		
		QueryText = StrReplace(QueryText, "Partner", "Counterparty");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// A check is being performed for the validity period.
// 
// Parameters:
//  TermsAndConditionsAttributes - See Documents.ConditionsOfCustomerRebates.UpToDateData
//  Cancel - Boolean
//
Procedure MonitoringCompletionOfValidityPeriod(TermsAndConditionsAttributes, Cancel)
	
	DateEmpty = Date(1, 1, 1);
	
	If BeginOfPeriod = DateEmpty
	 Or PeriodEnding = DateEmpty Then
		
		Return;
		
	EndIf;
	
	BeginningOfRebateOfRetroBonus = TermsAndConditionsAttributes.ValidOnDate;
	ExpirationOfRebateOfRetroBonus = TermsAndConditionsAttributes.ValidTo;
	AccrualFrequency = TermsAndConditionsAttributes.AccrualFrequency;
	
	ThereIsViolationOfBeginning = False;
	ThereIsViolationOfEnding = False;
	
	If BeginOfPeriod > PeriodEnding Then
			
		ErrorText = NStr("vi = 'Đầu kỳ không thể lớn hơn cuối kỳ';
						|ru = 'Начало периода не может быть больше его окончания';
						|en = 'Period start must be earlier than the period end'; fa = 'Period start must be earlier than the period end';
						|it = 'Начало периода не может быть больше его окончания';
						|pl = 'Period start must be earlier than the period end';
						|tr = 'Dönemin başlangıç tarihi, dönemin bitiş tarihinden büyük olamaz'");
		Common.MessageToUser(ErrorText,, "ValidOnDate", "Object", Cancel);
				
	ElsIf BeginOfPeriod > ExpirationOfRebateOfRetroBonus
	 Or PeriodEnding < BeginningOfRebateOfRetroBonus Then
		
		ThereIsViolationOfBeginning = True;
		ThereIsViolationOfEnding = True;
		ErrorText = NStr("vi = 'Chứng từ điều kiện không có hiệu lực trong kỳ tính toán đã chọn';
						|ru = 'Документ условия не действует в указанном периоде начисления';
						|en = 'The condition document is not available for the specified accrual period'; fa = 'The condition document is not available for the specified accrual period';
						|it = 'Документ условия не действует в указанном периоде начисления';
						|pl = 'The condition document is not available for the specified accrual period';
						|tr = 'Şartlar belgesi mevcut tahakkuk döneminde aktif değildir'");
		Common.MessageToUser(ErrorText,,,, Cancel);
		
	EndIf;
	
	ResultOfCheckingTimeFence = RebatesServer.CheckPeriodsByTimeFence(
		AccrualFrequency, 
		BeginOfPeriod,
		PeriodEnding,
		True);
		
	If ResultOfCheckingTimeFence.ThereIsViolationOfBeginning 
	   And Not ThereIsViolationOfBeginning Then
		
		Common.MessageToUser(
			ResultOfCheckingTimeFence.TextOfStartError,, "ValidOnDate", "Object", Cancel);
		
	EndIf;
		
	If ResultOfCheckingTimeFence.ThereIsViolationOfEnding
	   And Not ThereIsViolationOfEnding Then
		
		Common.MessageToUser(
			ResultOfCheckingTimeFence.TextOfEndingError,, "ValidTo", "Object", Cancel);
		
	EndIf;
		
EndProcedure

Procedure CheckFixationOfCompositionOfSegmentsOfURB(Cancel, SetLock, Val TermsAndConditionsAttributes = Undefined)
	
	PresentationOfConditionsDocument = Common.SubjectString(TermDocument);
	
	If SetLock Then
		
		Try
			
			Block = New DataLock();
			LockItem = Block.Add("InformationRegister.CustomerRebatesConditions");
			LockItem.SetValue("TermDocument", TermDocument);
			LockItem.Mode = DataLockMode.Shared;
			Block.Lock();
			
		Except
			
			ErrorTemplate = NStr("vi = 'Không thể kiểm tra việc ấn định thành phần của chứng từ %1 do nguyên nhân ""%2"".
								|Hãy thử lại sau';
								|ru = 'Не удалось выполнить проверку фиксации состава документа %1 по причине ""%2"".
								|Попробуйте позже';
								|en = 'Cannot check whether the %1 document is recorded due to ""%2"".
								|Try again later'; fa = 'Cannot check whether the %1 document is recorded due to ""%2"".
								|Try again later';
								|it = 'Cannot check whether the %1 document is recorded due to ""%2"".
								|Try again later';
								|pl = 'Cannot check whether the %1 document is recorded due to ""%2"".
								|Try again later';
								|tr = '%1 belgesinin içerik sabitleme kontrolü ""%2"" sebebiyle başarısız oldu.
								|Daha sonra tekrar deneyin'");
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplate,
				PresentationOfConditionsDocument,
				ErrorDescription);
			
			Raise ErrorText;
			
		EndTry;
		
		TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(TermDocument);
		
	ElsIf TermsAndConditionsAttributes = Undefined Then
		
		TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(TermDocument);
		
	EndIf;
	
	If TermsAndConditionsAttributes.Count() = 0 Then
		
		CompositionFixationIsAvailable = False;
		
	ElsIf TermsAndConditionsAttributes.ContentOfGoods = Enums.RebatesItems.ProductSegments
		  Or TermsAndConditionsAttributes.PartyList = Enums.RebatesParticipants.PartnersSegments
		  Or Not IsBlankString(TermsAndConditionsAttributes.ProductItemProperty) Then
		
		CompositionFixationIsAvailable = True;
		
	Else
		
		CompositionFixationIsAvailable = False;
		
	EndIf;
	
	If CompositionFixationIsAvailable
	   And Not TermsAndConditionsAttributes.RecordingIsCompleted Then
		
		MessageTemplate = NStr("vi = 'Trong chứng từ điều kiện %1 cần ấn định thành phần, nhưng chưa ấn định thành phần của chứng từ';
								|ru = 'В документе условий %1 необходима фиксация состава, но состав документа не зафиксирован';
								|en = 'The %1 condition document requires recording, but the document content is not recorded'; fa = 'The %1 condition document requires recording, but the document content is not recorded';
								|it = 'The %1 condition document requires recording, but the document content is not recorded';
								|pl = 'The %1 condition document requires recording, but the document content is not recorded';
								|tr = '%1 şartlar belgesinde içeriğin sabitlenmesi gerekmektedir, ancak belgenin içeriği sabitlenmemiştir'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			PresentationOfConditionsDocument);
		
		Common.MessageToUser(MessageText,, "TermDocument", "Object", Cancel);
		
	EndIf;
	
EndProcedure

// A check is being performed to ensure that the URB document has been approved, or if there has been an URB adjustment, then it is not in the status of approval.
// 
// Parameters:
//  Cancel - Boolean 
//  ExecuteWithLock - Boolean
// 
Procedure CheckStatusOfCurrentURB(Cancel, ExecuteWithLock = False)
	
	DataForControl = New Structure;
	DataForControl.Insert("CurrentTermsDocument", TermDocument);
	DataForControl.Insert("AdjustmentStatus", Enums.RebatesDocumentStatuses.EmptyRef());
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("TermDocument", TermDocument);
	FullName = Metadata.Documents.ConditionsOfCustomerRebates.FullName();
	Query.SetParameter("RefType", Common.MetadataObjectID(FullName));
	QueryText =
	"SELECT
	|	CustomerRebatesConditions.RecorderDocument AS CurrentTermsDocument
	|FROM
	|	InformationRegister.CustomerRebatesConditions AS CustomerRebatesConditions
	|WHERE
	|	CustomerRebatesConditions.TermDocument = &TermDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsRegistry.Ref AS CurrentTermsDocument,
	|	DocumentsRegistry.Status AS AdjustmentStatus
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.RefType = &RefType
	|	AND NOT DocumentsRegistry.DeletionMark
	|	AND DocumentsRegistry.Status <> VALUE(Enum.RebatesDocumentStatuses.Approved)
	|	AND DocumentsRegistry.CorrectedDocument = &TermDocument";
	Query.Text = QueryText;
	Result = Query.ExecuteBatch();
	
	ResultAccordingToRegister = Result[0];
	ResultAccordingToDocuments = Result[1];
	
	TermsDocumentHasNotBeenAgreed = ResultAccordingToRegister.IsEmpty();
	DocumentIsBeingCorrected = Not ResultAccordingToDocuments.IsEmpty();
	
	If DocumentIsBeingCorrected Then
		
		Selection = ResultAccordingToDocuments.Select();
		Selection.Next();
		FillPropertyValues(DataForControl, Selection);
		
	ElsIf Not TermsDocumentHasNotBeenAgreed Then
		
		Selection = ResultAccordingToRegister.Select();
		Selection.Next();
		FillPropertyValues(DataForControl, Selection);
		
	EndIf;
	
	If ExecuteWithLock Then
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add("Document.ConditionsOfCustomerRebates");
			LockItem.Mode = DataLockMode.Shared;
			LockItem.SetValue("Ref", DataForControl.CurrentTermsDocument);
			
			Block.Lock();
			
		Except
			
			ErrorTemplate = NStr("vi = 'Không thể kiểm tra trạng thái chứng từ điều kiện do nguyên nhân: ""%1"".
								|Hãy thử lại sau';
								|ru = 'Не удалось выполнить проверку статуса документа условий по причине: ""%1"".
								|Попробуйте позже';
								|en = 'Cannot check the document status due to ""%1"".
								|Try again later'; fa = 'Cannot check the document status due to ""%1"".
								|Try again later';
								|it = 'Не удалось выполнить проверку статуса документа условий по причине: ""%1"".
								|Попробуйте позже';
								|pl = 'Cannot check the document status due to ""%1"".
								|Try again later';
								|tr = 'Durum belgesinin durum kontrolü şu sebeple başarısız oldu: “%1”.
								|Daha sonra tekrar deneyin'");
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplate, 
				ErrorDescription);
			
			Raise ErrorText;
			
		EndTry;
		
	EndIf;
	
	If TermsDocumentHasNotBeenAgreed
	 Or DataForControl.AdjustmentStatus = Enums.RebatesDocumentStatuses.AwaitingApproval Then
		
		If ExecuteWithLock Then
			
			If TermsDocumentHasNotBeenAgreed Then
				
				MessageText = NStr("vi = 'Chưa thống nhất chứng từ điều kiện. Không thể kết chuyển chứng từ';
									|ru = 'Документ условий не согласован. Проведение документа невозможно';
									|en = 'The condition document is not approved. Cannot post the document'; fa = 'The condition document is not approved. Cannot post the document';
									|it = 'Документ условий не согласован. Проведение документа невозможно';
									|pl = 'The condition document is not approved. Cannot post the document';
									|tr = 'Koşullar belgesi kabul edilmedi. Belgenin uygulanması mümkün değil'");
				
			Else
				
				MessageText = NStr("vi = 'Chứng từ điều kiện đã nhập điều chỉnh đang chờ thống nhất. Không thể kết chuyển chứng từ';
									|ru = 'Для документа условий введена корректировка, которая находится на согласовании. Проведение документа невозможно';
									|en = 'Adjustment under approval is entered for the condition document. Cannot post the document'; fa = 'Adjustment under approval is entered for the condition document. Cannot post the document';
									|it = 'Для документа условий введена корректировка, которая находится на согласовании. Проведение документа невозможно';
									|pl = 'Adjustment under approval is entered for the condition document. Cannot post the document';
									|tr = 'Şartlar belgesi için bir düzeltme yapıldı ve onay aşamasına alındı. Belgenin uygulanması mümkün değildir'");
				
			EndIf;
			Common.MessageToUser(MessageText,, "TermDocument", "Object", Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckAccrualAmounts(Cancel)
	
	If Accruals.Count() = 0 Then
		Return;
	EndIf;
	
	ThereAreNonZeroSums = False;
	
	For Each AccrualLine In Accruals Do
		
		If AccrualLine.AmountBonusAccrued <> 0 Then
			
			ThereAreNonZeroSums = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not ThereAreNonZeroSums Then
		
		MessageText = NStr("vi = 'Trong phần bảng chưa chỉ ra số tiền nào cần tính toán';
							|ru = 'В табличной части не указано ни одной суммы к начислению';
							|en = 'There is no amount to accrue in the table'; fa = 'There is no amount to accrue in the table';
							|it = 'В табличной части не указано ни одной суммы к начислению';
							|pl = 'There is no amount to accrue in the table';
							|tr = 'Tabloda herhangi bir tahakkuk tutarı belirtilmemiş'");
		Common.MessageToUser(MessageText,, "Accruals", "Object", Cancel);
		
	EndIf;
	
EndProcedure

Procedure CheckAvailabilityOfSalesDocuments(Cancel)
	
	If Accruals.Count() = 0 Then
		Return;
	EndIf;
	
	ErrorText = NStr("vi = 'Chứng từ bán hàng không khả dụng';
					|ru = 'Документ продажи недоступен';
					|en = 'Sales document is unavailable'; fa = 'Sales document is unavailable';
					|it = 'Sales document is unavailable';
					|pl = 'Sales document is unavailable';
					|tr = 'Ödeme belgesi kullanılamıyor'");
	FieldPresentation = NStr("vi = 'Chứng từ bán hàng';
							|ru = 'Документ продажи';
							|en = 'Sales document'; fa = 'سند فروش';
							|it = 'Documento di vendita';
							|pl = 'Dokument sprzedaży';
							|tr = 'Satış belgesi'");
	TabularSectionPresentation = NStr("vi = 'Tính điểm';
										|ru = 'Начисления';
										|en = 'Accruals'; fa = 'اقلام تعهدی';
										|it = 'Accruals';
										|pl = 'Accruals';
										|tr = 'Tahakkuklar'");
	
	For LineNumber = 1 To Accruals.Count() Do
		
		AccrualLine = Accruals[LineNumber - 1];
		
		If Not ValueIsFilled(AccrualLine.DocumentSales) Then
			Continue;
		EndIf;
		
		ReadingAllowed = AccessManagement.ReadingAllowed(AccrualLine.DocumentSales);
		If Not ReadingAllowed Then
			
			NumAsString = Format(LineNumber, "NG=;");
			MessageText = CommonClientServer.FillingErrorText(
				"Column",
				"Correctness",
				FieldPresentation,
				NumAsString,
				TabularSectionPresentation,
				ErrorText);
			
			Field = CommonClientServer.PathToTabularSection("Accruals", LineNumber, "DocumentSales");
			Common.MessageToUser(MessageText,, Field, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf