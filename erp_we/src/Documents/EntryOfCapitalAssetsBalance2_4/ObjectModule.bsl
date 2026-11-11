
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If FillingData <> Undefined Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	InitializeDocumentBeforeFillingItOut();
	
	EntryOfCapitalAssetsBalanceLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	If Not RecordInOperationalAccounting And Not PostInFinancialAndTaxAccounting And Not RecordInMA Then
		MessageText = NStr("vi = 'Chứng từ phải được phản ánh trong một trong các tài khoản';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, hesaplardan birine yansıtılmalıdır'");
		Common.MessageToUser(MessageText, , 
			"Object.RecordInOperationalAccounting", , Cancel);
	EndIf;
	
	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Chứng từ phải được phản ánh trong một trong các tài khoản';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, hesaplardan birine yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.RecordInManAccounting",, Cancel);
	EndIf;
	
	NotCheckedAttributeArray.Add("ServicePaymentSchedule");
	NotCheckedAttributeArray.Add("ServiceAccrualSchedule");
	NotCheckedAttributeArray.Add("InterestAccrualSchedule");
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryFixedAssets Then
			
		NotCheckedAttributeArray.Add("IA");
		NotCheckedAttributeArray.Add("LeaseContractsARAP");
		NotCheckedAttributeArray.Add("OtherExpenses");
		NotCheckedAttributeArray.Add("LeasedAsset");
		
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("Counterparty");
		NotCheckedAttributeArray.Add("FinancialAccountingGroup");
		NotCheckedAttributeArray.Add("AssetsKind");
		
		CheckTSFilling("FA", CheckedAttributes, NotCheckedAttributeArray, Cancel);
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets Then
		
		NotCheckedAttributeArray.Add("FA");
		NotCheckedAttributeArray.Add("LeaseContractsARAP");
		NotCheckedAttributeArray.Add("OtherExpenses");
		NotCheckedAttributeArray.Add("LeasedAsset");
		
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("Counterparty");
		NotCheckedAttributeArray.Add("FinancialAccountingGroup");
		NotCheckedAttributeArray.Add("AssetsKind");
		
		CheckTSFilling("IA", CheckedAttributes, NotCheckedAttributeArray, Cancel);
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryInvestmentsInFixedAssets Then
		
		NotCheckedAttributeArray.Add("FA");
		NotCheckedAttributeArray.Add("IA");
		NotCheckedAttributeArray.Add("LeaseContractsARAP");
		NotCheckedAttributeArray.Add("LeasedAsset");

		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("Counterparty");
		NotCheckedAttributeArray.Add("FinancialAccountingGroup");
		NotCheckedAttributeArray.Add("FixedAssetsLocation");
		
		NotCheckedAttributeArray.Add("OtherExpenses.NonCurrentAsset");
		NotCheckedAttributeArray.Add("OtherExpenses.Sum");
		NotCheckedAttributeArray.Add("OtherExpenses.SumCompl");
		NotCheckedAttributeArray.Add("OtherExpenses.AmountExcludingVAT");
		
		CheckTSFilling("OtherExpenses", CheckedAttributes, NotCheckedAttributeArray, Cancel);

	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets Then
			
		NotCheckedAttributeArray.Add("IA");
		NotCheckedAttributeArray.Add("LeaseContractsARAP");
		NotCheckedAttributeArray.Add("OtherExpenses");
		NotCheckedAttributeArray.Add("LeasedAsset");
		
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("Counterparty");
		NotCheckedAttributeArray.Add("FinancialAccountingGroup");
		NotCheckedAttributeArray.Add("AssetsKind");
		
		CheckTSFilling("FA", CheckedAttributes, NotCheckedAttributeArray, Cancel);
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut Then
		
		NotCheckedAttributeArray.Add("IA");
		NotCheckedAttributeArray.Add("LeaseContractsARAP");
		NotCheckedAttributeArray.Add("OtherExpenses");
		NotCheckedAttributeArray.Add("LeasedAsset");
		
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("FinancialAccountingGroup");
		NotCheckedAttributeArray.Add("AssetsKind");
		NotCheckedAttributeArray.Add("FixedAssetsLocation");
		
		If ValueIsFilled(Organization) 
			And ValueIsFilled(Counterparty) 
			And (Organization = Counterparty) Then
			Text = NStr("vi = 'Trường ""Doanh nghiệp"" và ""Người cho thuê"" phải khác nhau.';
						|ru = 'Поля ""Организация"" и ""Арендатор"" должны различаться.';
						|en = 'The ""Company"" and ""Lessee"" fields must be different.'; fa = 'The ""Company"" and ""Lessee"" fields must be different.';
						|it = 'I campi ""Organizzazione"" e ""Locatore"" devono differire tra loro.';
						|pl = 'Pola ""Firma"" i ""Najemca"" powinny różnić się.';
						|tr = '""İş yeri"" ve ""Kiracı"" alanları farklı olmalıdır.'");
			Common.MessageToUser(Text, ThisObject, "Counterparty",, Cancel);
		EndIf;
		
		CheckTSFilling("FA", CheckedAttributes, NotCheckedAttributeArray, Cancel);
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryLeaseContractsARAP Then
		
		NotCheckedAttributeArray.Add("FA");
		NotCheckedAttributeArray.Add("IA");
		NotCheckedAttributeArray.Add("OtherExpenses");
		NotCheckedAttributeArray.Add("LeasedAsset");

		NotCheckedAttributeArray.Add("FinancialAccountingGroup");
		NotCheckedAttributeArray.Add("AssetsKind");
		NotCheckedAttributeArray.Add("FixedAssetsLocation");
		NotCheckedAttributeArray.Add("LeaseContractsARAP.SumCompl");
		
		If Not PostInFinancialAndTaxAccounting And Not RecordInMA Then
			NotCheckedAttributeArray.Add("LeaseContractsARAP.GLAccount");
		EndIf;

		CheckTSFilling("LeaseContractsARAP", CheckedAttributes, NotCheckedAttributeArray, Cancel);
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut Then
		
		NotCheckedAttributeArray.Add("FA");
		NotCheckedAttributeArray.Add("IA");
		NotCheckedAttributeArray.Add("LeaseContractsARAP");
		NotCheckedAttributeArray.Add("OtherExpenses");

		NotCheckedAttributeArray.Add("AssetsKind");
		
		If Not RecordInOperationalAccounting Then
			NotCheckedAttributeArray.Add("LeasedAsset.DateOfRecognition");
		EndIf; 
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets Then
		
		NotCheckedAttributeArray.Add("FA");
		NotCheckedAttributeArray.Add("IA");
		NotCheckedAttributeArray.Add("LeaseContractsARAP");
		NotCheckedAttributeArray.Add("OtherExpenses");
		
		NotCheckedAttributeArray.Add("AssetsKind");
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("LeasedAsset.Contract");
		
		If Not RecordInOperationalAccounting Then
			NotCheckedAttributeArray.Add("LeasedAsset.DateOfRecognition");
		EndIf; 
		
		CheckTSFilling("LeasedAsset", CheckedAttributes, NotCheckedAttributeArray, Cancel);

	EndIf; 
	
	ItemsAndDimensionsSelectionParameters = Documents.EntryOfCapitalAssetsBalance2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	EntryOfCapitalAssetsBalanceLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocumentBeforeFillingItOut();
	
	TMCommonUse.ClearDocumentIDs(
		ThisObject, "FA,IA,LeasedAsset,LeaseContractsARAP,PrepaymentsUnderLeaseContracts,OtherExpenses");
	
	EntryOfCapitalAssetsBalanceLocalization.OnCopy(ThisObject, CopiedObject);

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
			
		If BusinessOperation = Enums.BusinessTransactions.OBEntryFixedAssets
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut Then
			
			If RecordInOperationalAccounting Then
				NonCurrentAssetsInternal.CheckPossibilityOfTakingIntoAccountFA(ThisObject, Cancel);
			Else
				NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
			EndIf;

		ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets Then
			If RecordInOperationalAccounting Then
				NonCurrentAssetsInternal.CheckPossibilityOfAcceptingIAForAccounting(ThisObject, Cancel);
			Else
				NonCurrentAssetsInternal.CheckThatIAAreAcceptedForAccounting(ThisObject, Cancel);
			EndIf; 
		EndIf;
	EndIf;
	
	FillInBankingDetailsBeforeWrite();
	
	TMCommonUse.FillInDocumentIDs(
		ThisObject, "FA,IA,LeasedAsset,LeaseContractsARAP,PrepaymentsUnderLeaseContracts,OtherExpenses");
	
	EntryOfCapitalAssetsBalanceLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	EntryOfCapitalAssetsBalanceLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	EntryOfCapitalAssetsBalanceLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	EntryOfCapitalAssetsBalanceLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillChecking

Procedure CheckTSFilling(TSName, CheckedAttributes, NotCheckedAttributeArray, Cancel) Export

	If ThisObject[TSName].Count() = 0 Then
		Return;
	EndIf;
	
	If TSName = "FA" Then
		
		NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
			
		NonCurrentAssetsInternal.CheckDetailsOfFAWhenTakingIntoAccount(ThisObject, "FA", Cancel);
		
		CheckTSAttributes(TSName, Cancel);
		
	ElsIf TSName = "IA" Then
		
		NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "IA", "IntangibleAsset", Cancel);
			
		CheckTSAttributes(TSName, Cancel);

	ElsIf TSName = "OtherExpenses" Then
		
		CheckingTabularPartOtherExpenses(Cancel);
		
	ElsIf TSName = "LeasedAsset" Then
		
		NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "LeasedAsset", "FixedAsset", Cancel);
			
		NonCurrentAssetsInternal.CheckDetailsOfFAWhenTakingIntoAccount(ThisObject, TSName, Cancel);
			
	ElsIf TSName = "LeaseContractsARAP" Then
		
		NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "LeaseContractsARAP", "Contract", Cancel);
		
	EndIf; 
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// Universal verification performed based on the properties of the props: 
	//  - if the props are visible and not filled in, a message is displayed.
	//  - if the props are not visible or unavailable for editing, then it is not checked.
	UniversalTSCheck(TSName, CheckedAttributes, Cancel);
	
EndProcedure

Procedure UniversalTSCheck(TSName, CheckedAttributes, Cancel)

	UniversalTSVerificationParameters = Undefined;
	ObjectMetadata = Metadata();
	
	If TSName = "FA" Then
		
		UniversalTSVerificationParameters = New Structure;
		UniversalTSVerificationParameters.Insert("NameOfAccountingObject", "FixedAsset");
		UniversalTSVerificationParameters.Insert("MessageTemplate", NStr("vi = 'Trong thông tin tài sản ""%1"", trường %2 không được điền.';
																		|ru = 'В сведениях об основном средстве ""%1"" не заполнено поле %2.';
																		|en = 'Field %2 in the %1 fixed asset data is not filled in.'; fa = 'Field %2 in the %1 fixed asset data is not filled in.';
																		|it = 'Nei dati dell''immobilizzazione materiale ""%1"" non è stato compilato il campo %2.';
																		|pl = 'W danych o środku trwałym ""%1"" nie wypełniono pola %2.';
																		|tr = 'Sabit kıymet ""%1"" ayrıntılarında, %2alan doldurulmadı.'"));
		UniversalTSVerificationParameters.Insert("EditingInSeparateWindow", True);
		
	ElsIf TSName = "IA" Then
	
		UniversalTSVerificationParameters = New Structure;
		UniversalTSVerificationParameters.Insert("NameOfAccountingObject", "IntangibleAsset");
		UniversalTSVerificationParameters.Insert("MessageTemplate", NStr("vi = 'Trong thông tin về tài sản vô hình ''''%1'''', trường %2 không được điền.';
																		|ru = 'В сведениях о нематериальном активе ""%1"" не заполнено поле %2.';
																		|en = 'Field %2 in the %1 intangible asset data is not filled in.'; fa = 'Field %2 in the %1 intangible asset data is not filled in.';
																		|it = 'Nei dati dell''attivo immateriale ""%1"" non è stato compilato il campo %2.';
																		|pl = 'W danych o wartości niematerialnej ""%1"" nie wypełniono pola %2.';
																		|tr = 'Maddi olmayan varlık ""%1"" ayrıntılarında, %2alan doldurulmadı.'"));
		UniversalTSVerificationParameters.Insert("EditingInSeparateWindow", True);
		
	ElsIf TSName = "OtherExpenses" Then
		
		UniversalTSVerificationParameters = New Structure;
		UniversalTSVerificationParameters.Insert("NameOfAccountingObject", "NonCurrentAsset");
		UniversalTSVerificationParameters.Insert("MessageTemplate", NStr("vi = 'Cột ""%2"" trong hàng %1 của danh sách ""Chi phí"" không được điền';
																		|ru = 'Не заполнена колонка ""%2"" в строке %1 списка ""Расходы""';
																		|en = 'The ""%2"" column in %1 line of the Expenses list is not filled in'; fa = 'The ""%2"" column in %1 line of the Expenses list is not filled in';
																		|it = 'Non è stata compilata la colonna ""%2"" nella riga %1 dell''elenco ""Costi""';
																		|pl = 'Nie wypełniono kolumny ""%2"" w wierszu %1 listy ""Расходы""';
																		|tr = '""Giderler"" listesinin %1 satırındaki ""%2"" sütunu doldurulmamış'"));
		UniversalTSVerificationParameters.Insert("EditingInSeparateWindow", False);
		
	ElsIf TSName = "LeasedAsset" Then
		
		UniversalTSVerificationParameters = New Structure;
		UniversalTSVerificationParameters.Insert("NameOfAccountingObject", "FixedAsset");
		UniversalTSVerificationParameters.Insert("MessageTemplate", NStr("vi = 'Cột ""%2"" trong hàng %1 của danh sách Tài sản cố định không được điền';
																		|ru = 'Не заполнена колонка ""%2"" в строке %1 списка ""Основные средства""';
																		|en = 'The ""%2"" column in %1 line of the Fixed assets list is not filled in'; fa = 'The ""%2"" column in %1 line of the Fixed assets list is not filled in';
																		|it = 'La colonna ""%2"" nella riga %1 dell''elenco ""Capitale Fisso"" non è compilata';
																		|pl = 'Kolumna ""%2"" w wierszu %1 listy ""Środki trwałe"" nie jest wypełniona.';
																		|tr = '""Sabit kıymetler"" listesinin %1 satırındaki ""%2"" sütunu doldurulmamış'"));
		UniversalTSVerificationParameters.Insert("EditingInSeparateWindow", False);
		
	ElsIf TSName = "LeaseContractsARAP" Then
		
		UniversalTSVerificationParameters = New Structure;
		UniversalTSVerificationParameters.Insert("NameOfAccountingObject", "Contract");
		UniversalTSVerificationParameters.Insert("MessageTemplate", NStr("vi = 'Trong thông tin về tính toán theo hợp đồng ""%1"" chưa điền trường %2.';
																		|ru = 'В сведениях о расчетах по договору ""%1"" не заполнено поле %2.';
																		|en = 'The %2 field in the information on AR/AP under contract ""%1"" is not filled in.'; fa = 'The %2 field in the information on AR/AP under contract ""%1"" is not filled in.';
																		|it = 'Nelle informazioni sui conti in base all''accordo ""%1"" non è compilato il campo %2.';
																		|pl = 'W danych o rozliczeniach w ramach umowy ""%1"" nie wypełniono pola %2.';
																		|tr = '%2 alanı ""%1"" sözleşmesi kapsamındaki yerleşimlere ilişkin bilgilerde doldurulmamıştır.'"));
		UniversalTSVerificationParameters.Insert("EditingInSeparateWindow", True);
		
	EndIf;
	
	If UniversalTSVerificationParameters = Undefined Then
		Return;
	EndIf; 
	
	PathToProps = TSName + ".";
	VerifiableTSDetails = New Array;
	VerifiableDetailsWithoutTSName = New Array;
	For Each NameOfPropsToCheck In CheckedAttributes Do
		If StrStartsWith(NameOfPropsToCheck, PathToProps) Then
			VerifiableTSDetails.Add(NameOfPropsToCheck);
			VerifiableDetailsWithoutTSName.Add(StrSplit(NameOfPropsToCheck, ".")[1]);
		EndIf; 
	EndDo; 
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, VerifiableTSDetails);
	
	AuxiliaryDetailsOfObject = Documents.EntryOfCapitalAssetsBalance2_4.AuxiliaryAttributes(ThisObject, False);
	
	PresentationOfDetails = Undefined;
	For Each RowData In ThisObject[TSName] Do
		
		AuxiliaryAttributes = Documents.EntryOfCapitalAssetsBalance2_4.AddAuxiliaryDetailsBasedOnLineData(
										ThisObject, RowData, AuxiliaryDetailsOfObject);
		 
		ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_EnteringBalances(
										RowData, AuxiliaryAttributes);
		
		NotCheckedAttributeArray = New Array;
		NotCheckedAttributeArray.Add("ExpensesDimensionAccounting");
		NotCheckedAttributeArray.Add("ExpensesDimensionTaxAccounting");
		NotCheckedAttributeArray.Add("ExpensesDimensionManagementAccounting");
		NotCheckedAttributeArray.Add("DepreciationAllowanceExpensesDimension");
		NotCheckedAttributeArray.Add("ExpensesDimensionTax");
		TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
		For Each AttributeName In VerifiableDetailsWithoutTSName Do
			
			If NotCheckedAttributeArray.Find(AttributeName) <> Undefined Then
				Continue;
			EndIf;
			
			If Not ValueIsFilled(RowData[AttributeName]) Then
				
				AttributeRepresentation = NonCurrentAssetsInternal.AttributeRepresentation(
											AttributeName, TSName, PresentationOfDetails, ObjectMetadata);
											
				If UniversalTSVerificationParameters.EditingInSeparateWindow Then
					// When editing in a separate window, the message must be linked to the line number
					// so that when the message is selected, the editing form does not open.
					MessageText = StrTemplate(UniversalTSVerificationParameters.MessageTemplate, 
												RowData[UniversalTSVerificationParameters.NameOfAccountingObject], 
												AttributeRepresentation);
												
					Field = CommonClientServer.PathToTabularSection(TSName, RowData.LineNumber, "LineNumber");
				Else	
					MessageText = StrTemplate(UniversalTSVerificationParameters.MessageTemplate, 
												RowData.LineNumber, 
												AttributeRepresentation);
												
					Field = CommonClientServer.PathToTabularSection(TSName, RowData.LineNumber, AttributeName);
				EndIf; 
				
				Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
				
				// Used to get fill check errors from the calling code.
				NonCurrentAssetsInternal.AddFillInCheckResult(
					ThisObject,
					AttributeRepresentation,
					TSName,
					RowData.LineNumber,
					RowData[UniversalTSVerificationParameters.NameOfAccountingObject]);
				
			EndIf;
			
		EndDo; 
		
	EndDo;
	
EndProcedure

Procedure CheckingTabularPartOtherExpenses(Cancel)

	If AssetsKind = Enums.KindsOfNonCurrentAssets.ConstructionObjects Then
		AssetMessageTemplate = NStr("vi = 'Cột ""Đối tượng xây dựng"" không được điền vào dòng %1 của danh sách ""Chi phí""';
									|ru = 'Не заполнена колонка ""Объект строительства"" в строке %1 списка ""Расходы""';
									|en = 'The ""Assets under construction"" column in line #%1 of the Expenses list is not filled in'; fa = 'The ""Assets under construction"" column in line #%1 of the Expenses list is not filled in';
									|it = 'Non è stata compilata la colonna ""Oggetto di costruzione"" nella riga %1 dell''elenco ""Costi""';
									|pl = 'Nie wypełniono kolumny ""Объект строительства"" w wierszu %1 listy ""Расходы""';
									|tr = '"" Giderler"" listesinin %1 satırındaki ""İnşaat nesnesi"" sütunu doldurulmamış'");
		MessageTemplateAmount = NStr("vi = 'Bạn phải chỉ định số tiền đầu tư cho đối tượng xây dựng trong dòng %1 của danh sách ""Chi phí""';
									|ru = 'Необходимо указать сумму вложений для объекта строительства в строке %1 списка ""Расходы""';
									|en = 'Specify investment amount for the assets under construction in line %1 of the Expenses list'; fa = 'Specify investment amount for the assets under construction in line %1 of the Expenses list';
									|it = 'E'' necessario indicare l''importo di investimenti nell''oggetto di costruzione nella riga %1 dell''elenco ""Costi""';
									|pl = 'Należy wskazać wartość inwestycji dla obiektu budownictwa w wierszu %1 listy ""Расходы""';
									|tr = '""Giderler"" listesinin %1 satırında yapı nesnesi için yatırım miktarının belirtilmesi gerekmektedir.'");
	ElsIf AssetsKind = Enums.KindsOfNonCurrentAssets.IA Then
		AssetMessageTemplate = NStr("vi = 'Cột ""TSCĐVH (chi phí Nghiên cứu phát triển)"" trong hàng %1 của danh sách ""Chi phí"" không được điền';
									|ru = 'Не заполнена колонка ""НМА (расходы на НИОКР)"" в строке %1 списка ""Расходы""';
									|en = 'The ""Intangible assets (R&D expenses)"" column in line #%1 of the ""Expenses"" list is not filled in'; fa = 'The ""Intangible assets (R&D expenses)"" column in line #%1 of the ""Expenses"" list is not filled in';
									|it = 'Non è stata compilata la colonna ""Attività immateriali"" (costi per la ricerca e sviluppo) nella riga %1 dell''elenco ""Costi""';
									|pl = 'Nie wypełniono kolumny ""НМА (расходы на НИОКР)"" w wierszu %1 listy ""Расходы""';
									|tr = '""Giderler"" listesinin %1 satırındaki ""Maddi olmayan varlık (Ar-Ge giderleri)"" sütunu doldurulmamış'");
		MessageTemplateAmount = NStr("vi = 'Cần chỉ ra số tiền đầu tư cho Tài sản cố định vô hình (chi phí Chi phí nghiên cứu phát triển) trong dòng %1 của danh sách ""Chi phí""';
									|ru = 'Необходимо указать сумму вложений для НМА (расходов на НИОКР) в строке %1 списка ""Расходы""';
									|en = 'Specify investment amount for intangible assets (R&D expenses) in line %1 of the Expenses list'; fa = 'Specify investment amount for intangible assets (R&D expenses) in line %1 of the Expenses list';
									|it = 'E'' necessario indicare l''importo di investimenti per le attività immateriali (costi per la ricerca e sviluppo) nella riga %1 dell''elenco ""Costi""';
									|pl = 'Należy wskazać wartość inwestycji dla wartości niematerialnej (rozchodów na R&D) w wierszu %1 listy ""Расходы""';
									|tr = '""Harcamalar"" listesinin %1 satırında maddi olmayan varlık için yatırım miktarının (Ar-Ge harcaması) belirtilmesi gerekmektedir.'");
	Else
		AssetMessageTemplate = NStr("vi = 'Cột Tài sản cố định trong hàng %1 của danh sách Chi phí không được điền';
									|ru = 'Не заполнена колонка ""Основное средство"" в строке %1 списка ""Расходы""';
									|en = 'The ""Fixed asset"" column in line #%1 of the ""Expenses"" list is not filled in'; fa = 'The ""Fixed asset"" column in line #%1 of the ""Expenses"" list is not filled in';
									|it = 'Non è stata compilata la colonna ""Immobilizzazione materiale"" nella riga %1 dell''elenco ""Costi""';
									|pl = 'Nie wypełniono kolumny ""Основное средство"" w wierszu %1 listy ""Расходы""';
									|tr = 'Giderler listesinin %1 satırındaki sabit kıymet sütunu doldurulmamış'");
		MessageTemplateAmount = NStr("vi = 'Bạn phải chỉ định số tiền đầu tư cho tài sản cố định trong dòng %1 của danh sách ""Chi phí""';
									|ru = 'Необходимо указать сумму вложений для основного средства в строке %1 списка ""Расходы""';
									|en = 'Specify investment amount for the fixed asset in line %1 of the Expenses list'; fa = 'Specify investment amount for the fixed asset in line %1 of the Expenses list';
									|it = 'E'' necessario indicare l''importo di investimento per l''immobilizzazione materiale nella riga %1 dell''elenco ""Costi""';
									|pl = 'Należy wskazać wartość inwestycji dla środku trwałego w wierszu %1 listy ""Расходы""';
									|tr = '""Giderler"" listesinin %1 satırında sabit kıymet için yatırım tutarının belirtilmesi gerekmektedir.'");
	EndIf;
	
	For Each RowData In OtherExpenses Do
		
		If Not ValueIsFilled(RowData.NonCurrentAsset) Then
			MessageText = StrTemplate(AssetMessageTemplate, RowData.LineNumber);
			Field = CommonClientServer.PathToTabularSection("OtherExpenses", RowData.LineNumber, "NonCurrentAsset");
			Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
		EndIf;
		
		If Not ValueIsFilled(RowData.SumCompl) 
				And Not ValueIsFilled(RowData.AmountPermanentDifferences) 
				And Not ValueIsFilled(RowData.AmountTemporaryDifferences) 
				And RecordInLocalAccounting 
				And Not RecordInManAccounting
			Or Not ValueIsFilled(RowData.Sum) 
				And Not ValueIsFilled(RowData.AmountExcludingVAT) 
				And RecordInManAccounting 
				And Not RecordInLocalAccounting
			Or Not ValueIsFilled(RowData.Sum) 
				And Not ValueIsFilled(RowData.AmountExcludingVAT) 
				And Not ValueIsFilled(RowData.SumCompl) 
				And Not ValueIsFilled(RowData.AmountPermanentDifferences) 
				And Not ValueIsFilled(RowData.AmountTemporaryDifferences)
				And RecordInManAccounting 
				And RecordInLocalAccounting Then
				
			Field = CommonClientServer.PathToTabularSection("OtherExpenses", RowData.LineNumber, "NonCurrentAsset");
			MessageText = StrTemplate(MessageTemplateAmount, RowData.LineNumber);
			Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
		EndIf; 
		
	EndDo;
	
EndProcedure

Procedure CheckTSAttributes(TSName, Cancel)

	If Not RecordInOperationalAccounting Then
		Return;
	EndIf;

	For Each RowData In ThisObject[TSName] Do
		
		If RowData.DateOfRecognitionAccounting > Date
			And PostInAccounting Then
			
			MessageText = NStr("vi = 'Trong dòng %1 ngày tiếp nhận vào kế toán (doanh nghiệp) cần không muộn hơn ngày nhập số dư';
								|ru = 'В строке %1 дата принятия к учету (бух) должна быть не позже даты ввода остатков';
								|en = 'In line %1, the date of recognition (local) must be not later than the balance entry date'; fa = 'In line %1, the date of recognition (local) must be not later than the balance entry date';
								|it = 'В строке %1 дата принятия к учету (бух) должна быть не позже даты ввода остатков';
								|pl = 'In line %1, the date of recognition (local) must be not later than the balance entry date';
								|tr = '%1 satırında, kayıda kabul tarihi (muhasebe), bakiyelerin girildiği tarihten daha geç olmamalıdır'");
			MessageText = StrTemplate(MessageText, RowData.LineNumber);
											
			Field = CommonClientServer.PathToTabularSection(TSName, RowData.LineNumber, "LineNumber");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If RowData.DateOfRecognitionInTaxAccounting > Date
			And RecordInTA Then
			
			MessageText = NStr("vi = 'Trong dòng %1, ngày tiếp nhận vào kế toán (thuế) cần không muộn hơn ngày nhập số dư';
								|ru = 'В строке %1 дата принятия к учету (нал) должна быть не позже даты ввода остатков';
								|en = 'In line %1, the date of recognition (TA) must be not later than the balance entry date'; fa = 'In line %1, the date of recognition (TA) must be not later than the balance entry date';
								|it = 'В строке %1 дата принятия к учету (нал) должна быть не позже даты ввода остатков';
								|pl = 'In line %1, the date of recognition (TA) must be not later than the balance entry date';
								|tr = '%1 satırında, kayıda kabul tarihi (vergi muhasebesi), bakiyelerin girildiği tarihten daha geç olmamalıdır'");
			MessageText = StrTemplate(MessageText, RowData.LineNumber);
											
			Field = CommonClientServer.PathToTabularSection(TSName, RowData.LineNumber, "LineNumber");
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
											
			Field = CommonClientServer.PathToTabularSection(TSName, RowData.LineNumber, "LineNumber");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region DataProcessorBeforeWrite

Procedure FillInBankingDetailsBeforeWrite()
	
	If Not RecordInLocalAccounting Then
		RecordInLocalAccounting = PostInAccounting Or RecordInTA;
	EndIf;
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	For Each RowData In FA Do
		
		If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())))
			And CurrencyOfMan = ComplCurrency Then
	
			RowData.CurrentcCostManAcc = RowData.CurrentcCostFinAcc;
			RowData.AccumulatedDepreciationManagementAccounting = RowData.AccumulatedDepreciationAccounting;
			RowData.InitialCostMA = RowData.InitialCostLocalAccounting;
			RowData.CostRevaluationReserve = RowData.CostRevaluationReserveLocal;
			RowData.ResidualValueMan = RowData.ResidualValueLocal;
		EndIf;
		 
	EndDo; 
		
	For Each RowData In IA Do
		
		If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())))
			And CurrencyOfMan = ComplCurrency Then
				
			RowData.CurrentcCostManAcc = RowData.CurrentcCostFinAcc;
			RowData.AccumulatedDepreciationManagementAccounting = RowData.AccumulatedDepreciationAccounting;
			RowData.InitialCostMA = RowData.InitialCostLocalAccounting;
			RowData.CostRevaluationReserve = RowData.CostRevaluationReserveLocal;
		EndIf;
		 
	EndDo; 
	
	Documents.EntryOfCapitalAssetsBalance2_4.FillInAmountOfVATSettlementsUnderLeaseAgreements(ThisObject);
	
	EntryOfCapitalAssetsBalanceLocalization.ProcessFABeforeWriting(ThisObject);
	EntryOfCapitalAssetsBalanceLocalization.ProcessIABeforeRecording(ThisObject);
	
EndProcedure

#EndRegion

#Region Other

Procedure InitializeDocumentBeforeFillingItOut()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryInvestmentsInFixedAssets Then
		AssetsKind = Enums.KindsOfNonCurrentAssets.FixedAsset;
	EndIf;
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	RecordInOperationalAccounting = True;
	
	EntryOfCapitalAssetsBalanceLocalization.InitializeDocumentBeforeFillingItOut(ThisObject);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
