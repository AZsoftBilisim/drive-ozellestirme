
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillInSelectionDocument(FillingData, StandardProcessing);
		
	ElsIf FillInDataType = Type("CatalogRef.Assets") 
		Or FillInDataType = Type("Array")
			And FillingData.Count() <> 0
			And TypeOf(FillingData[0]) = Type("CatalogRef.Assets") Then
			
		FillOnBasisOfObjectsOfOperation(FillingData, Undefined, StandardProcessing);
		
	ElsIf FillInDataType = Type("DocumentRef.MergeOfFixedAssets") Then
		
		FillInBasedOnFAPooling(FillingData);
		
	EndIf;
	
	MergeOfFixedAssetsLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

	ItemsAndDimensionsSelectionParameters = Documents.MergeOfFixedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Comment = "";
	DocumentInAnotherAccounting = Undefined;
	
	InitializeDocumentBeforeFillingItOut();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	MergeOfFixedAssetsLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	ParametersForSelectingFixedAssets = ParametersForSelectingFixedAssets();
	
	AuxiliaryAttributes = AuxiliaryAttributes(ParametersForSelectingFixedAssets);
	ItemDetailsParameters = 
		NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_FAUnion(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckDocument(ParametersForSelectingFixedAssets, ItemDetailsParameters, CheckedAttributes, NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	MergeOfFixedAssetsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ParametersForSelectingFixedAssets);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not Cancel And WriteMode = DocumentWriteMode.Posting Then
		BlockData_();
		NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
		NonCurrentAssetsInternal.CheckThatFAIsNotReceivedForRentOnBalance(ThisObject, Cancel);
		If BusinessOperation = Enums.BusinessTransactions.MergeOfFixedAssets Then
			NonCurrentAssetsInternal.CheckPossibilityOfTakingIntoAccountFA(ThisObject, Cancel);
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
	FillInBankingDetailsBeforeWrite();
	
	MergeOfFixedAssetsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	ItemsAndDimensionsSelectionParameters = Documents.MergeOfFixedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	MergeOfFixedAssetsLocalization.OnWrite(ThisObject, Cancel);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	MergeOfFixedAssetsLocalization.Posting(ThisObject, Cancel, PostingMode);

EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	MergeOfFixedAssetsLocalization.UndoPosting(ThisObject, Cancel);

EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocumentBeforeFillingItOut()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If Not ValueIsFilled(FinancialAccountingGroup) Then
		FinancialAccountingGroup = Catalogs.NonCurrentAssetsAccountingGroups.DefaultValue(Enums.KindsOfNonCurrentAssets.FixedAsset);
	EndIf; 
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	
	VATTaxation = NonCurrentAssets.VATTaxation(Organization, Date);
	
	NonCurrentAssetsClientServer.WhenChangingBankingDetails_MergeFA(
		ThisObject, 
		AuxiliaryAttributes(), 
		"Organization,RecordInManAccounting,RecordInLocalAccounting");
	
EndProcedure

Procedure FillInSelectionDocument(Basis, StandardProcessing)

	If Basis.Property("FixedAsset") Then
		FillOnBasisOfObjectsOfOperation(Basis.FixedAsset, Basis, StandardProcessing);
	EndIf; 
	
EndProcedure

Procedure FillOnBasisOfObjectsOfOperation(Basis, FilterValues, StandardProcessing)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	SourceFA = ?(TypeOf(Basis) = Type("Array"), Basis, CommonClientServer.ValueInArray(Basis));
	
	ListOfFA = NonCurrentAssets.ReturnFAAcceptedForAccounting(SourceFA, Date);
	
	If ListOfFA.Count() = 0 Then
		
		MessageText = NStr("vi = 'Tài sản cố định nên được đưa vào tài khoản.';
							|ru = 'Основные средства должны быть приняты к учету.';
							|en = 'Fixed assets must be recognized.'; fa = 'Fixed assets must be recognized.';
							|it = 'Capitali fissi devono essere registrati in contabilità.';
							|pl = 'Środki trwałe powinne być przyjęte do ewidencji.';
							|tr = 'Sabit kıymetler muhasebeleştirilmelidir.'");
		Raise MessageText;
		
	EndIf;
	
	FALocation = NonCurrentAssets.FALocation(ListOfFA[0]);
	FillPropertyValues(ThisObject, FALocation, "Organization,FINANCIALLYLIABLEPERSON");
	Department = FALocation.FixedAssetsLocation;
	
	If FilterValues <> Undefined
		And FilterValues.Property("BusinessOperation") Then
		BusinessOperation = FilterValues.BusinessOperation;
	Else
		BusinessOperation = ?(SourceFA.Count() = 1,
									Enums.BusinessTransactions.AttachingToExistingFixedAsset,
									Enums.BusinessTransactions.MergeOfFixedAssets);
	EndIf; 
	
	For Each MainMeansBase In ListOfFA Do
		NewRow = FA.Add();
		NewRow.FixedAsset = MainMeansBase;
	EndDo;
	
	MergeOfSimilarFixedAssets = True;
	
	ParametersForSelectingFixedAssets = ParametersForSelectingFixedAssets();
	
	DescriptionOfProblems	= New Array;
	
	If ParametersForSelectingFixedAssets.ProblematicFA <> Undefined Then
		
		USCRemoval = New Array;
		
		For Each CheckResult In ParametersForSelectingFixedAssets.ProblematicFA Do
			
			If CheckResult.MainDirectionOfActivity
				Or CheckResult.TermOfUseOfMaDiffers
				Or CheckResult.PeriodOfUseOfBUDiffers
				Or MergeOfFixedAssetsLocalization.ThisIsNotSameTypeOfFAAccordingToResultsOfCheck(CheckResult) Then
				MergeOfSimilarFixedAssets = False;
			EndIf;
			
			If CheckResult.DifferentLocation Then
				
				MessageText = NStr("vi = '- tài sản cố định ""%1"" được đặt tại một Doanh nghiệp hoặc Bộ phận khác';
									|ru = '- основное средство ""%1"" находится в другой организации или подразделении';
									|en = '- fixed asset ""%1"" located in another company or division'; fa = '- fixed asset ""%1"" located in another company or division';
									|it = '- capitale fisso ""%1"" si trova in un''altra azienda o reparto';
									|pl = '- środek trwały ""%1"" znajduje się w innej firmy lub dziale';
									|tr = '- ""%1"" sabit kıymeti başka bir iş yerinde veya departmanda bulunmaktadır'");
				MessageText = StrTemplate(MessageText, CheckResult.FixedAssetPresentation);
				
				DescriptionOfProblems.Add(MessageText);
				
				USCRemoval.Add(CheckResult.FixedAsset);
				
			EndIf;
			
			If MergeOfFixedAssetsLocalization.CanBeMergedBasedOnValidationResults(CheckResult) Then
				USCRemoval.Add(CheckResult.FixedAsset);
			EndIf;
			
			MergeOfFixedAssetsLocalization.CompleteDescriptionOfProblemsWhenFillingOnBasisOfObjectOfOperation(CheckResult, DescriptionOfProblems);
			
		EndDo;
		
		For Each ProblemFA In USCRemoval Do
			RowData = FA.Find(ProblemFA, "FixedAsset");
			FA.Delete(RowData);
		EndDo;
		
	EndIf;
	
	For Each MainMeansBase In SourceFA Do
		If ListOfFA.Find(MainMeansBase) = Undefined Then
			MessageText = NStr("vi = '- tài sản cố định ""%1"" nên được hạch toán';
								|ru = '- основное средство ""%1"" должно быть принято к учету';
								|en = '- fixed asset ""%1"" must be recognized.'; fa = '- fixed asset ""%1"" must be recognized.';
								|it = '- capitale fisso ""%1"" deve esser registrato in contabilità';
								|pl = '- środek trwały ""%1"" powinien być przyjęty do ewidencji';
								|tr = '- ""%1"" sabit kıymetleri muhasebeye kaydedilmek zorundadır'");
			MessageText = StrTemplate(MessageText, MainMeansBase);
			DescriptionOfProblems.Add(MessageText);
		EndIf; 
	EndDo; 
	
	DescriptionOfProblems = StrConcat(DescriptionOfProblems, Chars.LF);
	
	If FA.Count() = 0 Then
			
		MessageText = ?(SourceFA.Count() = 1,
								NStr("vi = 'Không thể hợp nhất tài sản cố định đã chọn:
												|%1';
												|ru = 'Невозможно объединить выбранное основное средство:
												|%1';
												|en = 'Cannot merge selected fixed asset:
												|%1'; fa = 'Cannot merge selected fixed asset:
												|%1';
												|it = 'Impossibile unire il capitale fisso selezionato:
												|%1';
												|pl = 'Nie można połączyć wybrany środek trwały:
												|%1';
												|tr = 'Seçilen sabit kıymet birleştirilemez: 
												| %1'"),
								NStr("vi = 'Không thể hợp nhất tài sản cố định đã chọn:
												|%1';
												|ru = 'Невозможно объединить выбранные основные средства:
												|%1';
												|en = 'Cannot merge selected fixed assets:
												|%1'; fa = 'Cannot merge selected fixed assets:
												|%1';
												|it = 'Impossibile unire i capitali fissi selezionati:
												|%1';
												|pl = 'Nie można połączyć wybrane środki trwałe:
												|%1';
												|tr = 'Seçilen sabit kıymetler birleştirilemez: 
												| %1'"));
								
		MessageText = StrTemplate(MessageText, DescriptionOfProblems);
		
		Raise MessageText;
		
	EndIf;
	
	If ValueIsFilled(DescriptionOfProblems) Then
		MessageText = NStr("vi = 'Không thể thêm vào chứng từ một số tài sản cố định:
                               |%1';
                               |ru = 'Не удалось добавить в документ некоторые основные средства:
                               |%1';
                               |en = 'Failed to add some fixed assets to the document:
                               |%1'; fa = 'Failed to add some fixed assets to the document:
                               |%1';
                               |it = 'Non è stato possibile aggiungere nel documento alcuni capitali fissi:
                               |%1';
                               |pl = 'Nie udało się dodać do dokumentu niektóre środki trwałe:
                               |%1';
                               |tr = 'Belgeye bazı sabit kıymetler eklenemedi: 
                               | %1'");
		MessageText = StrTemplate(MessageText, DescriptionOfProblems);
		Common.MessageToUser(MessageText, ThisObject);
	EndIf;
	
	AuxiliaryAttributes = AuxiliaryAttributes(ParametersForSelectingFixedAssets);
	 
	NonCurrentAssetsClientServer.WhenChangingBankingDetails_MergeFA(
		ThisObject, AuxiliaryAttributes, "FixedAsset");
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_FAUnion(
									ThisObject, AuxiliaryAttributes);
	
	NonCurrentAssetsClientServer.FillInDetailsDependingOnProperties__FA_(ThisObject, ItemDetailsParameters);
	
EndProcedure

Procedure FillInBasedOnFAPooling(Basis)

	BaseObject = Basis.GetObject();
	
	FillPropertyValues(ThisObject, BaseObject,, "Number,Date,DataVersion,EmployeeResponsible,DeletionMark,Posted");
	
	DocumentInAnotherAccounting = Basis;
	
	For Each BaseString In BaseObject.FA Do
		LineOfATabularSection = FA.Add();
		LineOfATabularSection.FixedAsset = BaseString.FixedAsset;
	EndDo; 
	
	If NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		If BaseObject.RecordInLocalAccounting Then
			RecordInLocalAccounting = False;
			RecordInManAccounting  = True;
		Else
			RecordInLocalAccounting = True;
			RecordInManAccounting  = False;
		EndIf; 
	Else	
		RecordInLocalAccounting = True;
		RecordInManAccounting  = True;
	EndIf;
	
	ClearUnusedProps();
	
EndProcedure

#EndRegion

#Region FillChecking

Procedure CheckDocument(ParametersForSelectingFixedAssets, ItemDetailsParameters, CheckedAttributes, NotCheckedAttributeArray, Cancel)
	
	CheckAccountingParameters(ParametersForSelectingFixedAssets, Cancel);
	CheckFixedAssets(ParametersForSelectingFixedAssets, NotCheckedAttributeArray, Cancel);
	CheckDetailsAndExpenses(ItemDetailsParameters, CheckedAttributes, Cancel);

	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, kayıtlarının birinde yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.RecordInLocalAccounting",, Cancel);
	EndIf;
	
EndProcedure

Procedure CheckAccountingParameters(ParametersForSelectingFixedAssets, Cancel)

	If MergeOfSimilarFixedAssets
		And ParametersForSelectingFixedAssets.ParameterValues <> Undefined
		And ResidualUsefulLifeManagementAccounting_ > ParametersForSelectingFixedAssets.ParameterValues.UsefulLifeManagementAccounting
		And ParametersForSelectingFixedAssets.ParameterValues.UsefulLifeManagementAccounting <> 0
		And RecordInManAccounting Then
		
		MessageText = NStr("vi = 'Thời hạn sử dụng còn lại kế toán không thể vượt quá thời gian sử dụng tiêu chuẩn của %1 (tháng).';
							|ru = 'Остаточный срок использования в упр. учете не может превышать нормативный срок использования %1 (мес).';
							|en = 'Residual useful life in mgmt accounting can not exceed the standard useful life %1 (months).'; fa = 'Residual useful life in mgmt accounting can not exceed the standard useful life %1 (months).';
							|it = 'Vita utile residua in contabilità gestionale non può essere superiore alla vita utile standard %1 (mesi).';
							|pl = 'Pozostały okres użytkowania w ewidencji zarz. nie może być większa niż normatywny okres użytkowania %1 (mies).';
							|tr = 'Yönetim muhasebesinde kalan kullanım ömrü standart kullanım süresi olan %1''i (ay) aşamaz.'");
		MessageText = StrTemplate(MessageText, ParametersForSelectingFixedAssets.ParameterValues.UsefulLifeManagementAccounting);
		Common.MessageToUser(MessageText, ThisObject, "ResidualUsefulLifeManagementAccounting_",, Cancel);
		
	ElsIf Not MergeOfSimilarFixedAssets
		And ResidualUsefulLifeManagementAccounting_ > UsefulLifeManagementAccounting 
		And UsefulLifeManagementAccounting <> 0
		And RecordInManAccounting Then
		
		MessageText = NStr("vi = 'Thời hạn sử dụng còn lại kế toán không thể vượt quá thời gian sử dụng tiêu chuẩn của %1 (tháng).';
							|ru = 'Остаточный срок использования в упр. учете не может превышать нормативный срок использования %1 (мес).';
							|en = 'Residual useful life in mgmt accounting can not exceed the standard useful life %1 (months).'; fa = 'Residual useful life in mgmt accounting can not exceed the standard useful life %1 (months).';
							|it = 'Vita utile residua in contabilità gestionale non può essere superiore alla vita utile standard %1 (mesi).';
							|pl = 'Pozostały okres użytkowania w ewidencji zarz. nie może być większa niż normatywny okres użytkowania %1 (mies).';
							|tr = 'Yönetim muhasebesinde kalan kullanım ömrü standart kullanım süresi olan %1''i (ay) aşamaz.'");
		MessageText = StrTemplate(MessageText, UsefulLifeManagementAccounting);
		Common.MessageToUser(MessageText, ThisObject, "ResidualUsefulLifeManagementAccounting_",, Cancel);
		
	EndIf; 
	
	If MergeOfSimilarFixedAssets
		And ParametersForSelectingFixedAssets.ParameterValues <> Undefined
		And ResidualUsefulLifeAccounting_ > ParametersForSelectingFixedAssets.ParameterValues.UsefulLifeAccounting
		And ParametersForSelectingFixedAssets.ParameterValues.UsefulLifeAccounting <> 0
		And RecordInLocalAccounting Then
		
		MessageText = NStr("vi = 'Thời hạn sử dụng còn lại trong kế toán doanh nghiệp không thể vượt quá thời hạn sử dụng định mức %1 (tháng).';
							|ru = 'Остаточный срок использования в бух. учете не может превышать нормативный срок использования %1 (мес).';
							|en = 'Residual useful life in local accounting cannot exceed the standard useful life of %1 (months).'; fa = 'Residual useful life in local accounting cannot exceed the standard useful life of %1 (months).';
							|it = 'La vita utile residua in contabilità non può essere superiore al periodo di utilizzo a norma di legge %1 (mesi)';
							|pl = 'Pozostały okres użytkowania w ewidencji księgowej nie może być większa niż normatywny okres użytkowania %1 (mies).';
							|tr = 'Genel muhasebede kalan kullanım ömrü standart kullanım süresi olan %1''i (ay) aşamaz.'");
		MessageText = StrTemplate(MessageText, ParametersForSelectingFixedAssets.ParameterValues.UsefulLifeAccounting);
		Common.MessageToUser(MessageText, ThisObject, "ResidualUsefulLifeAccounting_",, Cancel);
		
	ElsIf Not MergeOfSimilarFixedAssets
		And ResidualUsefulLifeAccounting_ > UsefulLifeAccounting
		And UsefulLifeAccounting <> 0 
		And RecordInLocalAccounting Then
		
		MessageText = NStr("vi = 'Thời hạn sử dụng còn lại trong kế toán doanh nghiệp không thể vượt quá thời hạn sử dụng định mức %1 (tháng).';
							|ru = 'Остаточный срок использования в бух. учете не может превышать нормативный срок использования %1 (мес).';
							|en = 'Residual useful life in local accounting cannot exceed the standard useful life of %1 (months).'; fa = 'Residual useful life in local accounting cannot exceed the standard useful life of %1 (months).';
							|it = 'La vita utile residua in contabilità non può essere superiore al periodo di utilizzo a norma di legge %1 (mesi)';
							|pl = 'Pozostały okres użytkowania w ewidencji księgowej nie może być większa niż normatywny okres użytkowania %1 (mies).';
							|tr = 'Genel muhasebede kalan kullanım ömrü standart kullanım süresi olan %1''i (ay) aşamaz.'");
		MessageText = StrTemplate(MessageText, UsefulLifeAccounting);
		Common.MessageToUser(MessageText, ThisObject, "ResidualUsefulLifeAccounting_",, Cancel);
		
	EndIf; 
	
EndProcedure
 
Procedure CheckFixedAssets(ParametersForSelectingFixedAssets, NotCheckedAttributeArray, Cancel)

	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	NonCurrentAssetsInternal.CheckDetailsOfFAWhenTakingIntoAccount(ThisObject, Undefined, Cancel);
	NonCurrentAssetsInternal.CheckThatFAHasNotBeenTransferredToFinLease(ThisObject, Cancel);
	
	If BusinessOperation = Enums.BusinessTransactions.MergeOfFixedAssets Then
		NonCurrentAssetsInternal.CheckThatFAHaveBeenSelected(ThisObject, "FA", "FixedAsset", Cancel);
	EndIf;
	
	CheckSelectionOfFixedAssets(ParametersForSelectingFixedAssets, Cancel);
	
	If BusinessOperation = Enums.BusinessTransactions.MergeOfFixedAssets
		And FA.Count() = 1 Then
		
		MessageText = NStr("vi = 'Để kết hợp, bạn phải chọn một số tài sản cố định.';
							|ru = 'Для объединения необходимо выбрать несколько основных средств.';
							|en = 'To combine, several fixed assets should be selected.'; fa = 'To combine, several fixed assets should be selected.';
							|it = 'Per unire è necessario selezionare alcuni capitali fissi.';
							|pl = 'Dla połączenia należy wybrać kilka środków trwałych.';
							|tr = 'Birleştirmek için birden çok sabit kıymet seçmeniz gerekir.'");
		Common.MessageToUser(MessageText, ThisObject, "FA",, Cancel);
	EndIf;
	
	If ValueIsFilled(FixedAsset) Then
		
		RowData = FA.Find(FixedAsset, "FixedAsset");
		If RowData <> Undefined Then
			
			Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FixedAsset");
			
			If BusinessOperation = Enums.BusinessTransactions.MergeOfFixedAssets Then
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" không thể được chọn đồng thời trong danh sách tài sản cố định cố định và là tài sản cố định do kết hợp.';
									|ru = 'Основное средство ""%1"" не может быть выбрано одновременно в списке объединяемых основных средств и как основное средство, которое получено в результате объединения.';
									|en = 'The fixed asset ""%1"" cannot be selected both as fixed assets to be merged and as fixed asset as a result of merge.'; fa = 'The fixed asset ""%1"" cannot be selected both as fixed assets to be merged and as fixed asset as a result of merge.';
									|it = 'Il capitale fisso ""%1"" non può essere selezionato contemporaneamente nell''elenco di capitali fissi da unire e in qualità capitale fisso ottenuto come risultato dell''unione.';
									|pl = 'Środek trwały ""%1"" nie może być wybrany jednocześnie na liście połączanych środków trwałych i jak środek trwały, który został otrzymany w wyniku połączenia.';
									|tr = '""%1"" sabit kıymeti, birleştirilecek sabit kıymetler listesinde ve birleştirmeden türetilen bir sabit kıymet olarak aynı anda seçilemez.'");
				MessageText = StrTemplate(MessageText, String(RowData.FixedAsset));
			Else
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" không thể được đính kèm vào chính nó.';
									|ru = 'Основное средство ""%1"" не может быть присоединено к самому себе.';
									|en = 'The fixed asset ""%1"" cannot be attached to itself.'; fa = 'The fixed asset ""%1"" cannot be attached to itself.';
									|it = 'Il capitale fisso ""%1"" non può essere unito a se stesso.';
									|pl = 'Środek trwały ""%1"" nie może być dołączany sam do siebie.';
									|tr = 'Sabit kıymet ""%1"" kendisine eklenemez.'");
				MessageText = StrTemplate(MessageText, String(RowData.FixedAsset));
			EndIf; 
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure
 
Procedure CheckSelectionOfFixedAssets(ParametersForSelectingFixedAssets, Cancel)

	If ParametersForSelectingFixedAssets.ProblematicFA = Undefined Then
		Return;
	EndIf;
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	For Each RowData In FA Do
		
		CheckResult = ParametersForSelectingFixedAssets.ProblematicFA.Find(RowData.FixedAsset, "FixedAsset");
		If CheckResult = Undefined Then
			Continue;
		EndIf;
		
		Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FixedAsset");
		
		If CheckResult.DifferentLocation Then
			
			MessageText = NStr("vi = 'Tài sản cố định ""%1"" phải nằm trong doanh nghiệp và đơn vị được chọn';
								|ru = 'Основное средство ""%1"" должно находиться в выбранной организации и подразделении';
								|en = 'The fixed asset ""%1"" should be in the selected company and division'; fa = 'The fixed asset ""%1"" should be in the selected company and division';
								|it = 'Il capitale fisso ""%1"" deve trovarsi nell''azienda e nel reparto selezionati';
								|pl = 'Środek trwały ""%1"" powinien znajdować się w wybranej firmy i dziale';
								|tr = '""%1"" sabit kıymeti seçilen iş yerinde ve departmanda bulunmalıdır'");
			MessageText = StrTemplate(MessageText, CheckResult.FixedAssetPresentation);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If CheckResult.MainDirectionOfActivity Then
			
			If ValueIsFilled(CheckResult.LineOfBusiness) Then
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" phải có hoạt động ""%2""';
									|ru = 'У основного средства ""%1"" должно быть направление деятельности ""%2""';
									|en = 'The fixed asset ""%1"" should have the line of business ""%2""'; fa = 'The fixed asset ""%1"" should have the line of business ""%2""';
									|it = 'Il capitale fisso ""%1"" deve avere settore di attività ""%2""';
									|pl = 'Środek trwały ""%1"" powinien mieć rodzaj działalności ""%2""';
									|tr = '""%1"" sabit varlığının ""%2"" iş koluna sahip olması gerekir'");
				MessageText = StrTemplate(MessageText, 
									CheckResult.FixedAssetPresentation, 
									CheckResult.LineOfBusinessPresentation);
			Else
				MessageText = NStr("vi = 'Tài sản ""%1"" không nên có ngành nghề kinh doanh';
									|ru = 'У основного средства ""%1"" не должно быть указано направление деятельности';
									|en = 'The fixed asset ""%1"" should not have specified line of business'; fa = 'The fixed asset ""%1"" should not have specified line of business';
									|it = 'Il capitale fisso ""%1"" non deve avere l''indicazione del settore di attività';
									|pl = 'Środek trwały ""%1"" nie powinien mieć rodzaj działalności';
									|tr = '""%1"" sabit varlığının belirtilen bir iş kolu olmamalıdır'");
				MessageText = StrTemplate(MessageText, CheckResult.FixedAssetPresentation);
			EndIf; 
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If MergeOfSimilarFixedAssets
			And CheckResult.PeriodOfUseOfBUDiffers
			And Not CheckResult.NotAcceptedBU
			And Not CheckResult.AcceptedBU Then
			
			MessageText = NStr("vi = 'Tài sản cố định ""%1"" phải có thời hạn sử dụng trong kế toán doanh nghiệp là %2 tháng.';
								|ru = 'У основного средства ""%1"" должен быть срок использования в бух. учете %2 мес.';
								|en = '""%1"" fixed asset must have the useful life in local accounting of %2 months.'; fa = '""%1"" fixed asset must have the useful life in local accounting of %2 months.';
								|it = 'L''immobilizzazione ""%1"" deve avere un periodo di utilizzo in contabilità di %2 mesi.';
								|pl = 'Środek trwały ""%1"" powinien mieć okres użytkowania w ewidencji księgowej %2 mies.';
								|tr = '""%1"" sabit kıymetinin genel muhasebede kullanım ömrü %2 ay olmalıdır.'");
			MessageText = StrTemplate(MessageText, 
								CheckResult.FixedAssetPresentation, 
								CheckResult.UsefulLifeAccounting);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
	
		If MergeOfSimilarFixedAssets
			And CheckResult.TermOfUseOfMaDiffers Then
			
			MessageText = ?(ComplianceCAAccountingIsKept, 
								NStr("vi = 'Tài sản cố định ""%1"" phải có tuổi thọ sử dụng là chiếm %2 tháng';
									|ru = 'У основного средства ""%1"" должен быть срок использования в упр. учете %2 мес.';
									|en = 'The fixed asset ""%1"" should have the useful life in mgmt accounting %2 months.'; fa = 'The fixed asset ""%1"" should have the useful life in mgmt accounting %2 months.';
									|it = 'Il capitale fisso ""%1"" deve avere vita utile in contabilità gestionale di %2 mesi.';
									|pl = 'Środek trwały ""%1"" powinien mieć okres użytkowania w ewidencji zarz. %2 mies.';
									|tr = '""%1"" sabit kıymetinin yönetim muhasebesi kullanım ömrü %2 ay olmalıdır.'"),
								NStr("vi = 'Tài sản cố định ""%1"" phải có thời hạn sử dụng %2 tháng.';
									|ru = 'У основного средства ""%1"" должен быть срок использования %2 мес.';
									|en = 'The fixed asset ""%1"" should have the useful life %2 months.'; fa = 'The fixed asset ""%1"" should have the useful life %2 months.';
									|it = 'Il capitale fisso ""%1"" deve avere vita utile di %2 mesi.';
									|pl = 'Środek trwały ""%1"" powinien mieć okres użytkowania %2 mies.';
									|tr = '""%1"" sabit kıymetinin kullanım ömrü %2 ay olmalıdır.'"));
			
			MessageText = StrTemplate(MessageText, 
								CheckResult.FixedAssetPresentation, 
								CheckResult.UsefulLifeManagementAccounting);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If CheckResult.NotAcceptedByUU Then
			
			MessageText = NStr("vi = 'Để phản ánh chứng từ trong kế toán quản trị, cần tiếp nhận tài sản cố định ""%1"" vào kế toán trong kế toán quản trị.';
								|ru = 'Для отражения документа в управленческом учете необходимо, чтобы основное средство ""%1"" было принято к учету в управленческом учете.';
								|en = '""%1"" fixed asset must be recognized in management accounting to record the document in management accounting.'; fa = '""%1"" fixed asset must be recognized in management accounting to record the document in management accounting.';
								|it = 'Per riflettere il documento in contabilità gestionale è necessario che l''immobilizzazione ""%1"" sia ricevuta in contabilità gestionale.';
								|pl = 'W celu odzwierciedlenia dokumentu w ewidencji zarządczej należy , aby środek trwały ""%1"" był przyjęty do ewidencji w ewidencji zarządczej.';
								|tr = 'Belgenin yönetim muhasebesinde muhasebeleştirilebilmesi için ""%1"" sabit kıymetinin yönetim muhasebesinde kayıt için kabul edilmesi gerekir.'");
			MessageText = StrTemplate(MessageText, CheckResult.FixedAssetPresentation);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If CheckResult.NotAcceptedBU Then
			
			MessageText = NStr("vi = 'Để phản ánh chứng từ vào kế toán tài chính, cần tiếp nhận tài sản cố định ""%1"" vào kế toán trong kế toán doanh nghiệp.
								  |Không được phép gộp nhiều tài sản cố định, trong đó một TSCĐ đã được tiếp nhận, còn các TSCĐ khác chưa được tiếp nhận vào kế toán doanh nghiệp.';
								  |ru = 'Для отражения документа в регламентированном учете необходимо, чтобы основное средство ""%1"" было принято к учету в бухгалтерском учете.
								  |Не допускается объединять основные средства, где одно ОС принято в бухгалтерском учете, а другие не приняты.';
								  |en = '""%1"" fixed asset must be recognized in local accounting to record the document in local accounting.
								  |It is not allowed to merge the fixed assets where one fixed asset is recognized in local accounting, and others are not recognized.'; fa = '""%1"" fixed asset must be recognized in local accounting to record the document in local accounting.
								  |It is not allowed to merge the fixed assets where one fixed asset is recognized in local accounting, and others are not recognized.';
								  |it = 'Per riflettere il documento nella contabilità regolatoria è necessario che l''immobilizzazione ""%1"" sia ricevuta in contabilità.
								  |Non è possibile unire immobilizzazione quando una di queste è ricevuta in contabilità e altre non lo sono.';
								  |pl = 'W celu odzwierciedlenia dokumentu w ewidencji reglamentowanej należy, aby środek trwały ""%1"" był przyjęty do ewidencji w ewidencji księgowej.
								  |Nie jest dopuszczalne połączenie środków trwałych, gdzie jeden środek trwały jest przyjęty w ewidencji księgowej, a inne nie są przyjęte.';
								  |tr = 'Yerel muhasebede belgeyi yansıtmak için, ""%1"" sabit kıymetinin genel muhasebede kayıt için kabul edilmesi gerekir. 
								  | Bir sabit kıymetin genel muhasebede kabul edildiği ve diğerlerinin kabul edilmediği sabit kıymetlerin birleştirilmesine izin verilmez.'");
			MessageText = StrTemplate(MessageText, CheckResult.FixedAssetPresentation);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If CheckResult.AcceptedBU Then
			
			MessageText = NStr("vi = 'Để phản ánh chứng từ vào kế toán tài chính, không cần tiếp nhận tài sản cố định ""%1"" vào kế toán doanh nghiệp.
								  |Không được phép gộp nhiều tài sản cố định, trong đó một TSCĐ đã được tiếp nhận, còn các TSCĐ khác chưa được tiếp nhận vào kế toán doanh nghiệp.';
								  |ru = 'Для отражения документа в регламентированном учете необходимо, чтобы основное средство ""%1"" не было принято к учету в бухгалтерском учете.
								  |Не допускается объединять основные средства, где одно ОС принято в бухгалтерском учете, а другие не приняты.';
								  |en = '""%1"" fixed asset must not be recognized in local accounting to record the document in local accounting.
								  |It is not allowed to merge the fixed assets where one fixed asset is recognized in local accounting, and others are not recognized.'; fa = '""%1"" fixed asset must not be recognized in local accounting to record the document in local accounting.
								  |It is not allowed to merge the fixed assets where one fixed asset is recognized in local accounting, and others are not recognized.';
								  |it = 'Per riflettere il documento nella contabilità regolatoria è necessario che l''immobilizzazione ""%1"" non sia ricevuta in contabilità.
								  |Non è possibile unire immobilizzazione quando una di queste è ricevuta in contabilità e le altre non lo sono.';
								  |pl = 'W celu odzwierciedlenia dokumentu w ewidencji reglamentowanej należy, aby środek trwały ""%1"" nie był przyjęty do ewidencji w ewidencji księgowej.
								  |Nie jest dopuszczalne połączenie środków trwałych, gdzie jeden środek trwały jest przyjęty w ewidencji księgowej, a inne nie są przyjęte.';
								  |tr = 'Yerel muhasebede belgeyi yansıtmak için, ""%1"" sabit kıymetinin genel muhasebede kayıt için kabul edilmesi gerekir. 
								  | Bir sabit kıymetin genel muhasebede kabul edildiği ve diğerlerinin kabul edilmediği sabit kıymetlerin birleştirilmesine izin verilmez.'");
			MessageText = StrTemplate(MessageText, CheckResult.FixedAssetPresentation);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If CheckResult.AcceptedByUU Then
			
			MessageText = NStr("vi = 'Để phản ánh chứng từ vào kế toán quản trị, cần tiếp nhận tài sản cố định ""%1"" vào kế toán trong kế toán quản trị.
								  |Không được phép gộp nhiều tài sản cố định, trong đó một TSCĐ đã được tiếp nhận, còn các TSCĐ khác chưa được tiếp nhận vào kế toán quản trị.';
								  |ru = 'Для отражения документа в управленческом учете необходимо, чтобы основное средство ""%1"" не было принято к учету в управленческом учете.
								  |Не допускается объединять основные средства, где одно ОС принято в управленческом учете, а другие не приняты.';
								  |en = '""%1"" fixed asset must not be recognized in management accounting to record the document in management accounting.
								  |It is not allowed to merge the fixed assets where one fixed asset is recognized in management accounting, and others are not recognized.'; fa = '""%1"" fixed asset must not be recognized in management accounting to record the document in management accounting.
								  |It is not allowed to merge the fixed assets where one fixed asset is recognized in management accounting, and others are not recognized.';
								  |it = 'Per riflettere il documento in contabilità gestionale è necessario che l''immobilizzazione ""%1"" non sia ricevuta in contabilità gestionale.
								  |Non è possibile unire immobilizzazione quando una di queste è ricevuta in contabilità gestionale e le altre non lo sono.';
								  |pl = 'W celu odzwierciedlenia dokumentu w ewidencji zarządczej należy, aby środek trwały ""%1"" nie był przyjęty do ewidencji w ewidencji zarządczej.
								  |Nie jest dopuszczalne połączenie środków trwałych, gdzie jeden środek trwały jest przyjęty w ewidencji zarządczej, a inne nie są przyjęte.';
								  |tr = 'Yönetim muhasebesinde belgeyi yansıtmak için, ""%1"" sabit kıymetinin yönetim muhasebesine kayıt için kabul edilmesi gerekir. 
								  | Bir sabit kıymetin  yönetim muhasebesine kabul edildiği ve diğerlerinin kabul edilmediği sabit kıymetlerin birleştirilmesine izin verilmez.'");
			MessageText = StrTemplate(MessageText, CheckResult.FixedAssetPresentation);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If CheckResult.FAOwnerDoesNotMatch Then
			
			MessageText = NStr("vi = 'Bộ phận hoặc thành phần khấu hao ""%1"" cần được liên kết theo chủ sở hữu TSCĐ với Tài sản cố định mà nó có liên quan';
								|ru = 'Узел или компонент амортизации ""%1"" должен быть связан по ОС-владельцу с Основным средством, к которому он присоединяется';
								|en = 'The sub-asset or component of the ""%1"" depreciation must be linked by the fixed asset owner with the Fixed asset to which it is applied'; fa = 'The sub-asset or component of the ""%1"" depreciation must be linked by the fixed asset owner with the Fixed asset to which it is applied';
								|it = 'Il nodo o componente di ammortamento ""%1"" deve essere collegato tra proprietario e cespite al quale si collega';
								|pl = 'Węzeł lub komponent amortyzacji ""%1"" powienien być związany z właścicielem ŚT z Środkiem trwałym, z którym on łączy się';
								|tr = '""%1"" alt varlığı veya amortisman bileşeni, Sabit kıymet sahibi ile bağlı olduğu Sabit Kıymet ilişkili olmalıdır'");
			MessageText = StrTemplate(MessageText, CheckResult.FixedAssetPresentation);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		MergeOfFixedAssetsLocalization.ReportResultOfCheckingString(ThisObject, Field, CheckResult, Cancel);
		
	EndDo;
	
EndProcedure
 
Procedure CheckDetailsAndExpenses(ItemDetailsParameters, CheckedAttributes, Cancel)

	ItemsAndDimensionsSelectionParameters = Documents.MergeOfFixedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

#EndRegion

#Region Other

Procedure BlockData_()

	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.InitialFixedAssetsInformation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.FALocation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	Block.Lock(); 
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);

	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;

	If CurrencyOfMan = ComplCurrency Then
		ResidualValueMan = ResidualValueLocal;
	EndIf;
	
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_FAUnion(ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "FA");

EndProcedure

Function AuxiliaryAttributes(ParametersForSelectingFixedAssets = Undefined)
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("UseLocal", GetFunctionalOption("UseLocal"));
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInManAccounting", RecordInManAccounting);
	AuxiliaryAttributes.Insert("PostInAccounting", RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInTA", RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	AuxiliaryAttributes.Insert("ThereAreRelatedCompanies", Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Organization));

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	If ParametersForSelectingFixedAssets = Undefined Then
		ParametersForSelectingFixedAssets = ParametersForSelectingFixedAssets();
	EndIf; 
	
	AuxiliaryAttributes.Insert("AccordingToMaOperatingTime", ParametersForSelectingFixedAssets.AccordingToMaOperatingTime);
	AuxiliaryAttributes.Insert("AccordingToOperatingTimeOfAC", ParametersForSelectingFixedAssets.AccordingToOperatingTimeOfAC);
	AuxiliaryAttributes.Insert("AvailableMaDepreciationParameters", ParametersForSelectingFixedAssets.AvailableMaDepreciationParameters);
	AuxiliaryAttributes.Insert("ACDepreciationParametersAreAvailable", ParametersForSelectingFixedAssets.ACDepreciationParametersAreAvailable);
	AuxiliaryAttributes.Insert("UsedByCF", ParametersForSelectingFixedAssets.UsedByCF);

	AuxiliaryAttributes.Insert("AccountingProcedureAC", 
		?(ParametersForSelectingFixedAssets.ParameterValues <> Undefined, 
			ParametersForSelectingFixedAssets.ParameterValues.AccountingProcedureAC, 
			Undefined));
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()))));
		
	MergeOfFixedAssetsLocalization.AddAuxiliaryDetails(
		ThisObject, 
		ParametersForSelectingFixedAssets,
		AuxiliaryAttributes);
	
	Return AuxiliaryAttributes;

EndFunction

Function ParametersForSelectingFixedAssets()

	ListOfFA = New Array;
	For Each RowData In FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Ref", Ref);
	ProcedureParameters.Insert("FixedAsset", FixedAsset);
	ProcedureParameters.Insert("ListOfFA", ListOfFA);
	ProcedureParameters.Insert("Date", Date);
	ProcedureParameters.Insert("RecordInManAccounting", RecordInManAccounting);
	ProcedureParameters.Insert("RecordInLocalAccounting", RecordInLocalAccounting);
	ProcedureParameters.Insert("Organization", Organization);
	ProcedureParameters.Insert("FixedAssetsLocation", Department);
	ProcedureParameters.Insert("MergeOfSimilarFixedAssets", MergeOfSimilarFixedAssets);
	ProcedureParameters.Insert("BusinessOperation", BusinessOperation);
	
	ParametersForSelectingFixedAssets = Documents.MergeOfFixedAssets.ParametersForSelectingFixedAssets(ProcedureParameters);

	Return ParametersForSelectingFixedAssets;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
