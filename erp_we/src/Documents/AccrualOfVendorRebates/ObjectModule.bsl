//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("DocumentRef.ConditionsOfVendorRebates") Then
		
		DocumentReference = FillingData; // DocumentRef.ConditionsOfVendorRebates
		FillInAccordingToRebateConditionOfSuppliers(DocumentReference);
		
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
		NotCheckedAttributeArray.Add("Accruals.Products");
		NotCheckedAttributeArray.Add("Accruals.Characteristic");
		
	Else
		
		TermsAndConditionsAttributes = Documents.ConditionsOfVendorRebates.UpToDateData(TermDocument);
		
		If TermsAndConditionsAttributes.Count() > 0 Then
			
			CheckFixationOfCompositionOfSegmentsOfURB(Cancel, False, TermsAndConditionsAttributes);
			
			If BonusType <> Enums.VendorRebateTypes.Sales Then
				
				NotCheckedAttributeArray.Add("Accruals.Customer");
				
			EndIf;
			
			If BonusType = Enums.VendorRebateTypes.Balance Then
				
				NotCheckedAttributeArray.Add("BeginOfPeriod");
				NotCheckedAttributeArray.Add("PeriodEnding");
				
				FillVerificationParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
				FillVerificationParameters.TSName = Metadata().TabularSections.Accruals.Name;
				
				ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
					ThisObject,
					NotCheckedAttributeArray,
					Cancel,
					FillVerificationParameters);
				
			Else
				
				NotCheckedAttributeArray.Add("Accruals.Products");
				NotCheckedAttributeArray.Add("Accruals.Characteristic");
				
			EndIf;
			
			If TermsAndConditionsAttributes.BonusType = Enums.VendorRebateTypes.Purchases Then
				
				NotCheckedAttributeArray.Add("Counterparty");
				NotCheckedAttributeArray.Add("Partner");
				
			EndIf;
			
			MonitoringCompletionOfValidityPeriod(TermsAndConditionsAttributes, Cancel);
			
		Else
			
			NotCheckedAttributeArray.Add("Counterparty");
			NotCheckedAttributeArray.Add("Partner");
			NotCheckedAttributeArray.Add("BeginOfPeriod");
			NotCheckedAttributeArray.Add("PeriodEnding");
			NotCheckedAttributeArray.Add("Currency");
			NotCheckedAttributeArray.Add("Accruals");
			NotCheckedAttributeArray.Add("Accruals.Products");
			NotCheckedAttributeArray.Add("Accruals.Characteristic");
			NotCheckedAttributeArray.Add("Accruals.Customer");
			
		EndIf;
		
		CheckAccrualAmounts(Cancel);
		CheckAvailabilityOfPurchaseDocuments(Cancel);
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
	
	If Not TermDocument.IsEmpty() Then
		
		If WriteMode = DocumentWriteMode.Posting Then
			
			CheckFixationOfCompositionOfSegmentsOfURB(Cancel, True);
			CheckStatusOfCurrentURB(Cancel, True);
			
		EndIf;
		
	EndIf;
	
	For Each AccrualLine In Accruals Do
		
		If Not ValueIsFilled(AccrualLine.DocumentAcquisitions)
		   And AccrualLine.DocumentAcquisitions <> Undefined Then
			
			AccrualLine.DocumentAcquisitions = Undefined;
			
		EndIf;
		
	EndDo;
	
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
//  ConditionOfRebates - DocumentRef.ConditionsOfVendorRebates - fill-in data
//
Procedure FillInAccordingToRebateConditionOfSuppliers(ConditionOfRebates)
	
	TermsAndConditionsAttributes = Documents.ConditionsOfVendorRebates.UpToDateData(ConditionOfRebates);
	
	TermDocument = ConditionOfRebates;
	Organization = TermsAndConditionsAttributes.Organization;
	Counterparty = TermsAndConditionsAttributes.Counterparty;
	Partner = TermsAndConditionsAttributes.Partner;
	Contract = TermsAndConditionsAttributes.Contract;
	Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
	BeginOfPeriod = TermsAndConditionsAttributes.ValidOnDate;
	PeriodEnding = TermsAndConditionsAttributes.ValidTo;
	Currency = TermsAndConditionsAttributes.Currency;
	BonusType = TermsAndConditionsAttributes.BonusType;
	
	If Not ValueIsFilled(Currency)
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
	
	If TermsAndConditionsAttributes.WithoutCalculation
	   And TermsAndConditionsAttributes.AmountBonus <> 0 Then
		
		Accruals.Clear();
		NewRow = Accruals.Add();
		NewRow.AmountBonusAccrued = TermsAndConditionsAttributes.AmountBonus;
		NewRow.Counterparty = Counterparty;
		NewRow.Partner = Partner;
		NewRow.Contract = Contract;
		
	EndIf;
	
	If TermsAndConditionsAttributes.BonusType = Enums.VendorRebateTypes.Purchases Then
		
		VendorData = Documents.ConditionsOfVendorRebates.CurrentSupplierData(ConditionOfRebates);
		FillPropertyValues(ThisObject, VendorData);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// A check is being performed for the validity period.
// 
// Parameters:
//  TermsAndConditionsAttributes - See Documents.ConditionsOfVendorRebates.UpToDateData
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
		Common.MessageToUser(ErrorText,, "BeginOfPeriod", "Object", Cancel);
		
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
			ResultOfCheckingTimeFence.TextOfStartError,, "BeginOfPeriod", "Object", Cancel);
		
	EndIf;
	
	If ResultOfCheckingTimeFence.ThereIsViolationOfEnding
	   And Not ThereIsViolationOfEnding Then
		
		Common.MessageToUser(
			ResultOfCheckingTimeFence.TextOfEndingError,, "PeriodEnding", "Object", Cancel);
		
	EndIf;
	
EndProcedure

Procedure CheckFixationOfCompositionOfSegmentsOfURB(Cancel, SetLock, Val TermsAndConditionsAttributes = Undefined)
	
	PresentationOfConditionsDocument = Common.SubjectString(TermDocument);
	
	If SetLock Then
		
		Try
			
			Block = New DataLock();
			LockItem = Block.Add("InformationRegister.VendorRebatesConditions");
			LockItem.SetValue("TermDocument", TermDocument);
			LockItem.Mode = DataLockMode.Shared;
			Block.Lock();
			
		Except
			
			ErrorTemplate = NStr("vi = 'Không thể kiểm tra việc ấn định thành phần phân khúc chứng từ %1 do nguyên nhân ""%2"".
								|Hãy thử lại sau';
								|ru = 'Не удалось выполнить проверку фиксации состава сегментов документа %1 по причине ""%2"".
								|Попробуйте позже';
								|en = 'Cannot check whether the %1 document segments are recorded due to ""%2"".
								|Try again later'; fa = 'Cannot check whether the %1 document segments are recorded due to ""%2"".
								|Try again later';
								|it = 'Не удалось выполнить проверку фиксации состава сегментов документа %1 по причине ""%2"".
								|Попробуйте позже';
								|pl = 'Cannot check whether the %1 document segments are recorded due to ""%2"".
								|Try again later';
								|tr = '%1 belgesinin segment içeriğinin düzeltme kontrolü şu sebeple başarısız oldu: ""%2"".
								|Daha sonra tekrar deneyin'");
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplate,
				PresentationOfConditionsDocument,
				ErrorDescription);
			
			Raise ErrorText;
			
		EndTry;
		
		TermsAndConditionsAttributes = Documents.ConditionsOfVendorRebates.UpToDateData(TermDocument);
		
	ElsIf TermsAndConditionsAttributes = Undefined Then
		
		TermsAndConditionsAttributes = Documents.ConditionsOfVendorRebates.UpToDateData(TermDocument);
		
	EndIf;
	
	If TermsAndConditionsAttributes.Count() = 0 Then
		
		CompositionFixationIsAvailable = False;
		
	ElsIf TermsAndConditionsAttributes.ContentOfGoods = Enums.RebatesItems.ProductSegments
		  Or Not IsBlankString(TermsAndConditionsAttributes.ProductItemProperty) Then
		
		CompositionFixationIsAvailable = True;
		
	Else
		
		CompositionFixationIsAvailable = False;
		
	EndIf;
	
	If CompositionFixationIsAvailable
	   And Not TermsAndConditionsAttributes.RecordingIsCompleted Then
		
		MessageTemplate = NStr("vi = 'Trong chứng từ điều kiện %1 cần ấn định thành phần, nhưng chưa được ấn định thành phần phân khúc của chứng từ';
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
	FullName = Metadata.Documents.ConditionsOfVendorRebates.FullName();
	Query.SetParameter("RefType", Common.MetadataObjectID(FullName));
	QueryText =
	"SELECT
	|	Conditions.RecorderDocument AS CurrentTermsDocument
	|FROM
	|	InformationRegister.VendorRebatesConditions AS Conditions
	|WHERE
	|	Conditions.TermDocument = &TermDocument
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
			
			LockItem = Block.Add("Document.ConditionsOfVendorRebates");
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

Procedure CheckAvailabilityOfPurchaseDocuments(Cancel)
	
	If Accruals.Count() = 0 Then
		Return;
	EndIf;
	
	ErrorText = NStr("vi = 'Chứng từ mua hàng không khả dụng';
					|ru = 'Документ приобретения недоступен';
					|en = 'Purchase document is not available'; fa = 'Purchase document is not available';
					|it = 'Purchase document is not available';
					|pl = 'Purchase document is not available';
					|tr = 'Satın alma belgesi kullanılamıyor'");
	FieldPresentation = NStr("vi = 'Chứng từ mua hàng';
							|ru = 'Документ приобретения';
							|en = 'Purchase document'; fa = 'سند خرید';
							|it = 'Documento di acquisto';
							|pl = 'Dokument nabycia';
							|tr = 'Alım belgesi'");
	TabularSectionPresentation = NStr("vi = 'Tính toán';
										|ru = 'Начисления';
										|en = 'Accruals'; fa = 'اقلام تعهدی';
										|it = 'Accruals';
										|pl = 'Accruals';
										|tr = 'Tahakkuklar'");
	
	For LineNumber = 1 To Accruals.Count() Do
		
		AccrualLine = Accruals[LineNumber - 1];
		
		If Not ValueIsFilled(AccrualLine.DocumentAcquisitions) Then
			Continue;
		EndIf;
		
		ReadingAllowed = AccessManagement.ReadingAllowed(AccrualLine.DocumentAcquisitions);
		If Not ReadingAllowed Then
			
			NumAsString = Format(LineNumber, "NG=;");
			MessageText = CommonClientServer.FillingErrorText(
				"Column",
				"Correctness",
				FieldPresentation,
				NumAsString,
				TabularSectionPresentation,
				ErrorText);
			
			Field = CommonClientServer.PathToTabularSection("Accruals", LineNumber, "DocumentAcquisitions");
			Common.MessageToUser(MessageText,, Field, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf