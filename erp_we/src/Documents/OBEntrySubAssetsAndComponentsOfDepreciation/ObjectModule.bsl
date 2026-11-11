
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If FillingData <> Undefined Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	InitializeDocumentBeforeFillingItOut();
	
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	CheckBankingDetails(CheckedAttributes, NotCheckedAttributeArray, Cancel);
	CheckTSFilling(CheckedAttributes, NotCheckedAttributeArray, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntrySubAssetsAndComponentsOfDepreciation.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocumentBeforeFillingItOut();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not Cancel 
		And WriteMode = DocumentWriteMode.Posting 
		And NonCurrentAssets.VNAManagementIsUsed_2_4(Date) Then
			
		If RecordInOperationalAccounting Then
			NonCurrentAssetsInternal.CheckPossibilityOfTakingIntoAccountFA(ThisObject, Cancel);
		Else
			NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
		EndIf;

	EndIf;
	
	FillInBankingDetailsBeforeWrite();
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillChecking

Procedure CheckBankingDetails(CheckedAttributes, NotCheckedAttributeArray, Cancel)

	If Not RecordInOperationalAccounting And Not PostInFinancialAndTaxAccounting And Not RecordInMA Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Документ должен отражаться в одном из учетов';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, kayıtlarının birinde yansıtılmalıdır'");
		Common.MessageToUser(MessageText, , 
			"Object.RecordInOperationalAccounting", , Cancel);
	EndIf;
	
	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Документ должен отражаться в одном из учетов';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, kayıtlarının birinde yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.RecordInManAccounting",, Cancel);
	EndIf;
	
	SettingDate = EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()));
	AccountingSettings = AccountingPoliciesTaxSettingsCached.AccountingSettingsForNonCurrentAssets(Organization, SettingDate);
	
	If Not AccountingSettings.FSB6IsApplied
			And RecordInLocalAccounting
		Or AccountingSettings.AccountingPolicyForFixedAssets <> Enums.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards
			And RecordInManAccounting Then
		
		MessageText = NStr("vi = 'Việc tạo chứng từ được phép chỉ đối với các doanh nghiệp mà áp dụng ghi nhận TSCĐ theo quy định của kế toán doanh nghiệp và theo chuẩn mực của kế toán quốc tế trong kế toán quản trị';
							|ru = 'Оформление документа доступно только для организаций, применяющих учет ОС по ФСБУ 6 в бух. учете и по стандартам международного учета в упр. учете';
							|en = 'Only companies that apply fixed asset accounting in accordance with Russian GAAP 6 in local accounting and financial accounting standards in management accounting can register the document'; fa = 'Only companies that apply fixed asset accounting in accordance with Russian GAAP 6 in local accounting and financial accounting standards in management accounting can register the document';
							|it = 'Оформление документа доступно только для организаций, применяющих учет ОС по ФСБУ 6 в бух. учете и по стандартам международного учета в упр. учете';
							|pl = 'Only companies that apply fixed asset accounting in accordance with Russian GAAP 6 in local accounting and financial accounting standards in management accounting can register the document';
							|tr = 'Belgenin kaydı, yalnızca genel muhasebede FMUS 6''ya göre Sabit Kıymetin muhasebesini ve yönetim muhasebesinde uluslararası muhasebe standartlarına göre uygulayan kuruluşlar için geçerlidir'");
		Common.MessageToUser(MessageText, ThisObject, "Organization",, Cancel);
		
	EndIf;
	
EndProcedure

Procedure CheckTSFilling(CheckedAttributes, NotCheckedAttributeArray, Cancel) Export

	If FA.Count() = 0 Then
		Return;
	EndIf;
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
		
	NonCurrentAssetsInternal.CheckDetailsOfFAWhenTakingIntoAccount(ThisObject, "FA", Cancel);
	
	CheckTSAttributes(Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// Universal verification performed based on the properties of the props: 
	//  - if the props are visible and not filled in, a message is displayed.
	//  - if the props are not visible or unavailable for editing, then it is not checked.
	UniversalTSCheck(CheckedAttributes, Cancel);
	
EndProcedure

Procedure UniversalTSCheck(CheckedAttributes, Cancel)

	UniversalTSVerificationParameters = Undefined;
	ObjectMetadata = Metadata();
	
	UniversalTSVerificationParameters = New Structure;
	UniversalTSVerificationParameters.Insert("NameOfAccountingObject", "FixedAsset");
	UniversalTSVerificationParameters.Insert("MessageTemplate", NStr("vi = 'Trong thông tin về tài sản cố định ""%1"", chưa điền trường %2.';
																	|ru = 'В сведениях об основном средстве ""%1"" не заполнено поле %2.';
																	|en = 'Field %2 in the %1 fixed asset data is not filled in.'; fa = 'Field %2 in the %1 fixed asset data is not filled in.';
																	|it = 'В сведениях об основном средстве ""%1"" не заполнено поле %2.';
																	|pl = 'W danych o środku trwałym ""%1"" nie wypełniono pola %2.';
																	|tr = 'Sabit kıymet ""%1"" ayrıntılarında, %2alan doldurulmadı.'"));
	UniversalTSVerificationParameters.Insert("EditingInSeparateWindow", True);
		
	If UniversalTSVerificationParameters = Undefined Then
		Return;
	EndIf; 
	
	PathToProps = "FA" + ".";
	VerifiableTSDetails = New Array;
	VerifiableDetailsWithoutTSName = New Array;
	For Each NameOfPropsToCheck In CheckedAttributes Do
		If StrStartsWith(NameOfPropsToCheck, PathToProps) Then
			VerifiableTSDetails.Add(NameOfPropsToCheck);
			VerifiableDetailsWithoutTSName.Add(StrSplit(NameOfPropsToCheck, ".")[1]);
		EndIf; 
	EndDo; 
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, VerifiableTSDetails);
	
	AuxiliaryAttributes = Documents.OBEntrySubAssetsAndComponentsOfDepreciation.AuxiliaryAttributes(ThisObject, False);
	
	PresentationOfDetails = Undefined;
	
	For Each RowData In FA Do
		
		ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_OBEntry_NodesComponents(
										RowData, AuxiliaryAttributes);
		
		NotCheckedAttributeArray = New Array;
		NotCheckedAttributeArray.Add("ExpensesDimensionAccounting");
		NotCheckedAttributeArray.Add("ExpensesDimensionManagementAccounting");
		TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
		For Each AttributeName In VerifiableDetailsWithoutTSName Do
			
			If NotCheckedAttributeArray.Find(AttributeName) <> Undefined Then
				Continue;
			EndIf;
			
			If Not ValueIsFilled(RowData[AttributeName]) Then
				
				AttributeRepresentation = NonCurrentAssetsInternal.AttributeRepresentation(
											AttributeName, "FA", PresentationOfDetails, ObjectMetadata);
											
				If UniversalTSVerificationParameters.EditingInSeparateWindow Then
					// When editing in a separate window, the message must be linked to the line number
					// so that when the message is selected, the editing form does not open.
					MessageText = StrTemplate(UniversalTSVerificationParameters.MessageTemplate, 
												RowData[UniversalTSVerificationParameters.NameOfAccountingObject], 
												AttributeRepresentation);
												
					Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "LineNumber");
				Else	
					MessageText = StrTemplate(UniversalTSVerificationParameters.MessageTemplate, 
												RowData.LineNumber, 
												AttributeRepresentation);
												
					Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, AttributeName);
				EndIf; 
				
				Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
				
				// Used to get fill check errors from the calling code.
				NonCurrentAssetsInternal.AddFillInCheckResult(
					ThisObject,
					AttributeRepresentation,
					"FA",
					RowData.LineNumber,
					RowData[UniversalTSVerificationParameters.NameOfAccountingObject]);
				
			EndIf;
			
		EndDo; 
		
	EndDo;
	
EndProcedure

Procedure CheckTSAttributes(Cancel)

	If Not RecordInOperationalAccounting Then
		Return;
	EndIf;
	
	For Each RowData In FA Do
		
		If RowData.DateOfRecognitionAccounting > Date
			And RecordInLocalAccounting Then
			
			MessageText = NStr("vi = 'Trong dòng %1 ngày tiếp nhận vào kế toán (doanh nghiệp) cần không muộn hơn ngày nhập số dư';
								|ru = 'В строке %1 дата принятия к учету (бух) должна быть не позже даты ввода остатков';
								|en = 'In line %1, the date of recognition (local) must be not later than the balance entry date'; fa = 'In line %1, the date of recognition (local) must be not later than the balance entry date';
								|it = 'В строке %1 дата принятия к учету (бух) должна быть не позже даты ввода остатков';
								|pl = 'In line %1, the date of recognition (local) must be not later than the balance entry date';
								|tr = '%1 satırında, kayıda kabul tarihi (muhasebe), bakiyelerin girildiği tarihten daha geç olmamalıdır'");
			MessageText = StrTemplate(MessageText, RowData.LineNumber);
											
			Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "LineNumber");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If RowData.DateOfRecognitionManagementAccounting > Date
			And RecordInManAccounting Then
			
			MessageText = NStr("vi = 'Trong dòng %1, ngày tiếp nhận vào kế toán (quản trị) cần không muộn hơn ngày nhập số dư';
								|ru = 'В строке %1 дата принятия к учету (упр) должна быть не позже даты ввода остатков';
								|en = 'In line %1, the date of recognition (mgmt) must be not later than the balance entry date'; fa = 'In line %1, the date of recognition (mgmt) must be not later than the balance entry date';
								|it = 'В строке %1 дата принятия к учету (упр) должна быть не позже даты ввода остатков';
								|pl = 'In line %1, the date of recognition (mgmt) must be not later than the balance entry date';
								|tr = '%1 satırında, kayıda kabul tarihi (yönetim muhasebesi), bakiyelerin girildiği tarihten daha geç olmamalıdır'");
			MessageText = StrTemplate(MessageText, RowData.LineNumber);
											
			Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "LineNumber");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region DataProcessorBeforeWrite

Procedure FillInBankingDetailsBeforeWrite()
		
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	For Each RowData In FA Do
		
		If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())))
			And CurrencyOfMan = ComplCurrency Then
	
			RowData.CurrentcCostManAcc = RowData.CurrentcCostFinAcc;
			RowData.AccumulatedDepreciationManagementAccounting = RowData.AccumulatedDepreciationAccounting;
			RowData.InitialCostMA = RowData.InitialCostLocalAccounting;
			RowData.ResidualValueMan = RowData.ResidualValueLocal;
		EndIf;
		 
	EndDo; 
		
EndProcedure

#EndRegion

#Region Other

Procedure InitializeDocumentBeforeFillingItOut()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	RecordInOperationalAccounting = True;
	
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.InitializeDocumentBeforeFillingItOut(ThisObject);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
