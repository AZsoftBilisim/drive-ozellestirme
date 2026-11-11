#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocument();
	
	BasisType = TypeOf(FillingData);
	If BasisType = Type("Structure") Then
		TypeOfParameterChangeOperation = Undefined;
		
		If FillingData.Property("OperationKind",TypeOfParameterChangeOperation) Then
			If TypeOfParameterChangeOperation = "ChangingCGU" Then
				FillInCGUChange(FillingData);
			EndIf;
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
	ElsIf BasisType = Type("CatalogRef.IntangibleAssets") Then
		FillInBasedOnIntangibleAsset(FillingData);
	ElsIf BasisType = Type("DocumentRef.IntangibleAssetsInitialRecognition2_4") Then
		FillInBasedOnAcceptanceForAccounting(FillingData);
	ElsIf BasisType = Type("DocumentRef.IATransfer2_4") Then
		FillBasedOnMovement(FillingData);
	ElsIf BasisType = Type("DocumentRef.ChangeIntangibleAssetFinancialDetails2_4") Then
		FillBasedOnParameterChanges(FillingData);
	ElsIf BasisType = Type("DocumentRef.IntangibleAssetsCostAndAmortizationAdjustment") Then
		FillInBasedOnCostAdjustmentAndDepreciationOfIa(FillingData);
	ElsIf BasisType = Type("DocumentRef.IntangibleAssetImprovement") Then
		FillInBasedOnImprovementOfIA(FillingData);
	EndIf;
	
	ChangeIntangibleAssetFinancialDetailsLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_ChangingIAParameters(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "IA", "IntangibleAsset", Cancel);
		
	CheckReflectionInAccounting(Cancel);
	CheckIfSettingsMatch(Cancel);
	CheckParametersFilling(Cancel);
	CheckDepreciation(NotCheckedAttributeArray, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.ChangeIntangibleAssetFinancialDetails2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ChangeIntangibleAssetFinancialDetailsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		NonCurrentAssetsInternal.CheckThatIAAreAcceptedForAccounting(ThisObject, Cancel);
	EndIf;
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_ChangingIAParameters(ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "Depreciation");
	
	If Depreciation.Count() = 1
		And Depreciation[0].ZoomRatio = 0 Then
		Depreciation[0].ZoomRatio = 1;
	EndIf;
	
	DepreciationFactorAmount = Depreciation.Total("ZoomRatio");
	AmountOfPreviousRowsFactors = 0;
	For Each RowData In Depreciation Do
		RowData.AmountOfPreviousRowsFactors = AmountOfPreviousRowsFactors;
		AmountOfPreviousRowsFactors = AmountOfPreviousRowsFactors + RowData.ZoomRatio;
	EndDo;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "IA");
		
	ItemsAndDimensionsSelectionParameters = Documents.ChangeIntangibleAssetFinancialDetails2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ChangeIntangibleAssetFinancialDetailsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ChangeIntangibleAssetFinancialDetailsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentInAnotherAccounting = Undefined;
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "IA");
	
	ChangeIntangibleAssetFinancialDetailsLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockData_();
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ChangeIntangibleAssetFinancialDetailsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ChangeIntangibleAssetFinancialDetailsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	ItemsAndDimensionsSelectionParameters = Documents.ChangeIntangibleAssetFinancialDetails2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("IntangibleAsset") Then
		FillInBasedOnIntangibleAsset(Basis.IntangibleAsset);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnIntangibleAsset(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "IsFolder");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể thay đổi tham số nhóm TSCĐ vô hình.
			|Hãy chọn TSCĐ vô hình. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Изменение параметров группы НМА невозможно.
			|Выберите НМА. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot change intangible assets group parameters.
			|Select intangible assets. To expand the group, press Ctrl+Down.'; fa = 'Cannot change intangible assets group parameters.
			|Select intangible assets. To expand the group, press Ctrl+Down.';
			|it = 'La modifica dei parametri del gruppo di Beni Immateriali non è possibile. 
			|Selezionare i beni immateriali. Per aprire il gruppo premere Ctrl e freccia verso il basso.';
			|pl = 'Zmiana  parametrów grupy WNM nie jest możliwa.
			| Wybierz WNM. Aby rozwinąć grupę, użyj klawisza Ctrl i strzałki w dół.';
			|tr = 'Maddi olmayan varlık grubunun ayarlarını değiştiremezsiniz. 
			| Maddi olmayan varlık seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	InitialInformation = Catalogs.IntangibleAssets.InitialInformation(Basis, Date);

	IntangibleAssetsRegistrationPlace = NonCurrentAssets.IntangibleAssetsRegistrationPlace(Basis);
	FillPropertyValues(ThisObject, IntangibleAssetsRegistrationPlace);
	
	LineOfATabularSection = IA.Add();
	LineOfATabularSection.IntangibleAsset = Basis;
	
	RecordInManAccounting = ValueIsFilled(InitialInformation.DocumentOfRecognitionManagementAccounting);
	
	PostInAccounting = ValueIsFilled(InitialInformation.DocumentOfRecognitionAccounting);
	RecordInTA = ValueIsFilled(InitialInformation.RecognitionDocumentTA);
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;
	
EndProcedure

Procedure FillInBasedOnAcceptanceForAccounting(Basis)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.IntangibleAsset AS IntangibleAsset,
	|	&Basis AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA
	|FROM
	|	Document.IntangibleAssetsInitialRecognition2_4 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Basis";
	
	Query.SetParameter("Basis", Basis);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
		IA.Add().IntangibleAsset = Selection.IntangibleAsset;
	EndIf;
	
EndProcedure

Procedure FillBasedOnParameterChanges(Basis, IntangibleAsset = Undefined)

	BaseObject = Basis.GetObject();
	
	FillPropertyValues(ThisObject, BaseObject,, "Number,Date,DataVersion,EmployeeResponsible,DeletionMark,Posted");
	DocumentInAnotherAccounting = Basis;
	
	If Not ValueIsFilled(IntangibleAsset) Then
		For Each BaseString In BaseObject.IA Do
			LineOfATabularSection = IA.Add();
			LineOfATabularSection.IntangibleAsset = BaseString.IntangibleAsset;
		EndDo; 
		IA.Load(BaseObject.IA.Unload());
	Else
		LineOfATabularSection = IA.Add();
		LineOfATabularSection.IntangibleAsset = IntangibleAsset;
	EndIf; 
	
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
	
	PostInAccounting = RecordInLocalAccounting;
	RecordInTA = RecordInLocalAccounting And NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
EndProcedure

Procedure FillBasedOnMovement(Basis)
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferIntangibleAssetsToBranchOffice)
	|			THEN DocumentData.CompanyRecipient
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|FROM
	|	Document.IATransfer2_4 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.IntangibleAsset AS IntangibleAsset
	|FROM
	|	Document.IATransfer2_4.IA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Basis);
	Package = Query.ExecuteBatch();
	
	If Not Package[0].IsEmpty() Then
		Selection = Package[0].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
		PostInAccounting = RecordInLocalAccounting;
		RecordInTA = RecordInLocalAccounting And NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		IA.Load(Package[1].Unload());
	EndIf;
	
EndProcedure

Procedure FillInBasedOnCostAdjustmentAndDepreciationOfIa(Basis)
	
	QueryText =
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|FROM
	|	Document.IntangibleAssetsCostAndAmortizationAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.IntangibleAsset AS IntangibleAsset
	|FROM
	|	Document.IntangibleAssetsCostAndAmortizationAdjustment.IA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Basis);
	Package = Query.ExecuteBatch();
	
	If Not Package[0].IsEmpty() Then
		Selection = Package[0].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		IA.Load(Package[1].Unload());
	EndIf;
	
EndProcedure

Procedure FillInBasedOnImprovementOfIA(Basis)
	
	QueryText =
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|FROM
	|	Document.IntangibleAssetImprovement AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.IntangibleAsset AS IntangibleAsset
	|FROM
	|	Document.IntangibleAssetImprovement.IA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Basis);
	Package = Query.ExecuteBatch();
	
	If Not Package[0].IsEmpty() Then
		Selection = Package[0].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		IA.Load(Package[1].Unload());
	EndIf;
	
EndProcedure

Procedure FillInCGUChange(FillingData)
	
	FillPropertyValues(ThisObject, FillingData);
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	For Each IAString In FillingData.IA Do
		IALineOfDocument  = IA.Add();
		IALineOfDocument.IntangibleAsset = IAString.IntangibleAsset;
	EndDo;	
		
EndProcedure

#EndRegion

#Region FillChecking

Procedure CheckParametersFilling(Cancel)
	
	If Not AccountingProcedureACFlag
		And Not AccountingProcedureMAFlag
		And Not DepreciationAccrualMethodManagementAccountingFlag
		And Not UsefulLifeManagementAccountingFlag
		And Not EstimatedRunningTimeFlag
		And Not AccelerationFactorManagementAccountingFlag
		And Not ResidualValueManFlag
		And Not ResidualValueLocalFlag
		And Not FinancialAccountingGroupFlag
		And Not DepreciationExpenseRecordingIsChanged
		And Not LineOfBusinessFlag
		And Not DepreciationMethodAccountingFlag
		And Not UsefulLifeAccountingFlag
		And Not DepreciationAccrualFactorFlag
		And Not CGUFlag
		And Not ChangeIntangibleAssetFinancialDetailsLocalization.ParametersSelected(ThisObject) Then
		
		Common.MessageToUser(NStr("vi = 'Bạn phải chọn tham số biến';
									|ru = 'Необходимо выбрать изменяемые параметры';
									|en = 'Select changing parameters'; fa = 'Select changing parameters';
									|it = 'È necessario selezionare i parametri modificabili';
									|pl = 'Należy wybrać zmieniane parametry';
									|tr = 'Değiştirmek istediğiniz parametreleri seçmeniz gerekir'"), Ref,,, Cancel);
		Return; 
	EndIf;
	
	CheckThatChangeableParametersAreUsed(Cancel);

EndProcedure

Procedure CheckThatChangeableParametersAreUsed(Cancel)
	
	If IA.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	MAX(CheckResult.ItIsNotAllowedToChangeAccelerationCoefficientOfBU) AS ItIsNotAllowedToChangeAccelerationCoefficientOfBU,
	|	MAX(CheckResult.AccrualMethodForOperatingTimeIsNotUsed) AS AccrualMethodForOperatingTimeIsNotUsed,
	|	MAX(CheckResult.ItIsNotAllowedToChangeAccelerationCoefficientOfMa) AS ItIsNotAllowedToChangeAccelerationCoefficientOfMa
	|FROM
	|	(SELECT
	|
			// ItIsNotAllowedToChangeAccelerationCoefficientOfBU
	|		&DepreciationAccrualFactorFlag
	|		AND (NOT &DepreciationMethodAccountingFlag
	|					AND InitialIntangibleAssetsInformation.DepreciationMethodAccounting <> VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)
	|			OR &DepreciationMethodAccountingFlag
	|					AND &DepreciationMethodAccounting <> VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)) AS ItIsNotAllowedToChangeAccelerationCoefficientOfBU,
	|		
			// AccrualMethodForOperatingTimeIsNotUsed
	|		&EstimatedRunningTimeFlag
	|		AND NOT (NOT &DepreciationAccrualMethodManagementAccountingFlag
	|					AND IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod IN (&MethodsForOperatingTime)
	|				OR &DepreciationAccrualMethodManagementAccountingFlag
	|					AND &DepreciationAccrualMethodManagementAccounting IN (&MethodsForOperatingTime)
	|				OR NOT &DepreciationMethodAccountingFlag
	|					AND InitialIntangibleAssetsInformation.DepreciationMethodAccounting IN (&MethodsForOperatingTime)
	|				OR &DepreciationMethodAccountingFlag
	|					AND &DepreciationMethodAccounting IN (&MethodsForOperatingTime)) AS AccrualMethodForOperatingTimeIsNotUsed,
	|
			// ItIsNotAllowedToChangeAccelerationCoefficientOfMa
	|		&AccelerationFactorManagementAccountingFlag
	|		AND (NOT &DepreciationAccrualMethodManagementAccountingFlag
	|					AND IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod <> VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)
	|			OR &DepreciationAccrualMethodManagementAccountingFlag
	|					AND &DepreciationAccrualMethodManagementAccounting <> VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance)) AS ItIsNotAllowedToChangeAccelerationCoefficientOfMa
	|	FROM
	|		Catalog.IntangibleAssets AS IntangibleAssets
	|
	|		LEFT JOIN InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
	|				&Date, 
	|				Recorder <> &Ref
	|					AND Organization = &Organization
	|					AND IntangibleAsset IN (&ListOfIA)) AS InitialIntangibleAssetsInformation
	|		ON InitialIntangibleAssetsInformation.IntangibleAsset = IntangibleAssets.Ref
	|			AND InitialIntangibleAssetsInformation.Organization = &Organization
	|
	|		LEFT JOIN InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting.SliceLast(
	|				&Date, 
	|				Recorder <> &Ref
	|					AND Organization = &Organization
	|					AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetAmortizationParametersManagementAccounting
	|		ON IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset = IntangibleAssets.Ref
	|			AND IntangibleAssetAmortizationParametersManagementAccounting.Organization = &Organization
	|	WHERE
	|		IntangibleAssets.Ref IN (&ListOfIA)
	|
	|	) AS CheckResult
	|
	|HAVING
	|	MAX(CheckResult.ItIsNotAllowedToChangeAccelerationCoefficientOfBU) = TRUE
	|		OR MAX(CheckResult.AccrualMethodForOperatingTimeIsNotUsed) = TRUE
	|		OR MAX(CheckResult.ItIsNotAllowedToChangeAccelerationCoefficientOfMa) = TRUE";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ListOfIA", IA.UnloadColumn("IntangibleAsset"));
	
	Query.SetParameter("DepreciationAccrualFactorFlag", DepreciationAccrualFactorFlag);
	Query.SetParameter("DepreciationMethodAccountingFlag", DepreciationMethodAccountingFlag);
	Query.SetParameter("DepreciationMethodAccounting", DepreciationMethodAccounting);

	Query.SetParameter("DepreciationAccrualMethodManagementAccountingFlag", DepreciationAccrualMethodManagementAccountingFlag);
	Query.SetParameter("DepreciationAccrualMethodManagementAccounting", DepreciationAccrualMethodManagementAccounting);
	Query.SetParameter("AccelerationFactorManagementAccountingFlag", AccelerationFactorManagementAccountingFlag);
	Query.SetParameter("EstimatedRunningTimeFlag", EstimatedRunningTimeFlag);

	MethodsForOperatingTime = New Array;
	MethodsForOperatingTime.Add(Enums.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction);
	Query.SetParameter("MethodsForOperatingTime", MethodsForOperatingTime);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();

	If Selection.ItIsNotAllowedToChangeAccelerationCoefficientOfMa Then
		MessageText = NStr("vi = 'Để thay đổi tham số ""Hệ số tăng tốc (kế toán quản trị)"" tài sản cố định vô hình phải có cách tính khấu hao của ""Số dư tối thiểu"".';
							|ru = 'Для изменения параметра ""Коэффициент ускорения (управленческий учет)"" у НМА должен быть способ начисления амортизации ""Уменьшаемого остатка"".';
							|en = 'Intangible assets must have ""Declining balance"" method of amortization charge to change the ""Acceleration factor (management accounting)"" parameter.'; fa = 'Intangible assets must have ""Declining balance"" method of amortization charge to change the ""Acceleration factor (management accounting)"" parameter.';
							|it = 'Per modificare il parametro ""Coefficiente di accelerazione (contabilità gestionale"", l''ammortamento del Bene immateriale deve essere calcolato con il metodo di ""Saldo decrescente"".';
							|pl = 'Aby zmienić parametr ""Współczynnik przyspieszenia (ewidencja zarządcza)"" ANM powinien mieć sposób naliczenia amortyzacji ""Malejącego salda"".';
							|tr = '""Hızlandırma faktörü (yönetim muhasebesi)"" parametresini değiştirmek için, Maddi olmayan varlığın ""Azalan bakiye"" amortismanını hesaplamaya yönelik bir yöntemi olmalıdır.'");
		Common.MessageToUser(MessageText, ThisObject, "AccelerationFactorManagementAccountingFlag",, Cancel);
	EndIf;

	If Selection.AccrualMethodForOperatingTimeIsNotUsed Then
		MessageText = NStr("vi = 'Để thay đổi tham số ""Thời gian hoạt động ước tính"", tài sản cố định vô hình phải có phương pháp khấu hao ""Tỷ lệ thuận với khối lượng sản xuất"".';
							|ru = 'Для изменения параметра ""Предполагаемый объем наработки"" у НМА должен быть способ начисления амортизации ""Пропорционально объему"".';
							|en = 'Intangible assets must have ""Units-of-activity"" method of amortization charge to change the ""Estimated asset activity value"" parameter.'; fa = 'Intangible assets must have ""Units-of-activity"" method of amortization charge to change the ""Estimated asset activity value"" parameter.';
							|it = 'Per modificare il parametro ""Volume di produzione stimato"" del Bene immateriale, l''ammortamento di questo bene deve essere calcolato con il metodo ""Proporzionale al volume"".';
							|pl = 'Aby zmienić parametr ""Przewidywana objętość czasu pracy"" aktywa niematerialne powinny mieć sposób naliczenia amortyzacji ""Proporcjonalnie do objętości"".';
							|tr = '""Tahmini çalışma hacmi"" parametresini değiştirmek için, Maddi olmayan varlıkın ""Hacimle orantılı"" bir amortisman yöntemine sahip olması gerekir.'");
		Common.MessageToUser(MessageText, ThisObject, "EstimatedRunningTimeFlag",, Cancel);
	EndIf;
	
	If Selection.ItIsNotAllowedToChangeAccelerationCoefficientOfBU Then
		MessageText = NStr("vi = 'Để thay đổi tham số ""Hệ số khấu hao nhanh (kế toán doanh nghiệp)"" đối với TSCĐ vô hình cần có phương thức tính khấu hao ""Số dư giảm dần"".';
							|ru = 'Для изменения параметра ""Коэффициент ускорения (бухгалтерский учет)"" у НМА должен быть способ начисления амортизации ""Уменьшаемого остатка"".';
							|en = 'Intangible asset must have the ""Declining balance"" amortization charge method to change the ""Acceleration factor (local accounting)"" parameter.'; fa = 'Intangible asset must have the ""Declining balance"" amortization charge method to change the ""Acceleration factor (local accounting)"" parameter.';
							|it = 'Per la modifica del parametro ""Coefficiente di accelerazione (contabilità)"" presso i beni immateriali deve esservi il metodo di calcolo dell''ammortamento ""A saldo decrescente"".';
							|pl = 'Aby zmienić parametr ""Współczynnik przyspieszenia (ewidencja księgowa)"" Aktywa niematerialne powininny mieć sposób naliczenia amortyzacji ""Zmniejszającego stanu"".';
							|tr = '""Hızlandırma faktörü (muhasebe)"" parametresini değiştirmek için, Maddi olmayan varlıkın ""Azalan bakiye"" amortismanını hesaplamak için bir yöntemi olmalıdır.'");
		Common.MessageToUser(MessageText, ThisObject, "DepreciationAccrualFactorFlag",, Cancel);
	EndIf;
	
EndProcedure

Procedure CheckIfSettingsMatch(Cancel)
	
	If Not FinancialAccountingGroupFlag Or Not ValueIsFilled(FinancialAccountingGroup) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	CheckTable.IntangibleAsset AS IntangibleAsset,
	|	CheckTable.IntangibleAsset.Presentation AS IntangibleAssetPresentation,
	|	CheckTable.IncorrectHFC AS IncorrectHFC,
	|	CheckTable.NoChangeInDepreciationIsAllowed AS NoChangeInDepreciationIsAllowed
	|FROM
	|	(SELECT
	|		IntangibleAssets.Ref AS IntangibleAsset,
	|		IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset)
	|				AND FAG.AssetKind <> VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|			OR IntangibleAssets.KindOfAccountingObject = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|				AND FAG.AssetKind <> VALUE(Enum.KindsOfNonCurrentAssets.RD) AS IncorrectHFC,
	|		IntangibleAssets.KindOfAccountingObject <> VALUE(Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset)
	|			AND &DepreciationAccrualTaxAccountingFlag AS NoChangeInDepreciationIsAllowed
	|	FROM
	|		Catalog.IntangibleAssets AS IntangibleAssets
	|			LEFT JOIN Catalog.NonCurrentAssetsAccountingGroups AS FAG
	|			ON (FAG.Ref = &FAG)
	|	WHERE
	|		IntangibleAssets.Ref IN(&IntangibleAssets)) AS CheckTable
	|WHERE
	|	(CheckTable.IncorrectHFC = TRUE
	|			OR CheckTable.NoChangeInDepreciationIsAllowed = TRUE)";
	
	Query = New Query(QueryText);
	Query.SetParameter("IntangibleAssets", IA.UnloadColumn("IntangibleAsset"));
	Query.SetParameter("FAG", FinancialAccountingGroup);
	Query.SetParameter("DepreciationAccrualTaxAccountingFlag", DepreciationAccrualTaxAccountingFlag And RecordInTA);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		RowData = IA.Find(Selection.IntangibleAsset, "IntangibleAsset");
		
		Path = CommonClientServer.PathToTabularSection("IA", RowData.LineNumber, "IntangibleAsset");
		
		If Selection.IncorrectHFC = True Then
			MessageText = NStr("vi = 'Dạng đối tượng kế toán tài sản vô hình ""%1"" không khớp với loại tài sản của nhóm kế toán tài chính.';
								|ru = 'Вид объекта учета нематериального актива ""%1"" не соответствует виду актива группы финансового учета.';
								|en = 'Kind of accounting object of the ""%1"" intangible asset does not correspond to the asset type of financial accounting group.'; fa = 'Kind of accounting object of the ""%1"" intangible asset does not correspond to the asset type of financial accounting group.';
								|it = 'La tipologia di bene immateriale ""%1"" non corrisponde alla tipologia di bene del gruppo di contabilità finanziaria.';
								|pl = 'Rodzaj obiektu ewidencji wartości niematarialnej ""%1"" nie odpowiada rodzajowi aktyw grupy ewidencji finansowej.';
								|tr = '""%1"" maddi olmayan duran varlığın muhasebe nesnesi türü, finansal muhasebe grubunun varlık türüne karşılık gelmiyor.'");
			MessageText = StrTemplate(MessageText, Selection.IntangibleAssetPresentation);
			Common.MessageToUser(MessageText, ThisObject, Path,, Cancel);
		EndIf; 
			
		If Selection.NoChangeInDepreciationIsAllowed = True Then
			MessageText = NStr("vi = 'Đối với chi phí Nghiên cứu phát triển ""%1"", không được phép thay đổi chi phí khấu hao.';
								|ru = 'Для расходов на НИОКР ""%1"" не допускается изменение начисления амортизации.';
								|en = 'Cannot change amortization charge for R&D expenses ""%1"".'; fa = 'Cannot change amortization charge for R&D expenses ""%1"".';
								|it = 'La modifica dell''onere di ammortamento per le spese per la ricerca e lo sviluppo ""%1"" non è ammessa.';
								|pl = 'Dla wydatków na R&D ""%1"" nie jest dopuszczalna zmiana naliczania amortyzacji.';
								|tr = 'Ar-Ge harcaması ""%1"" için amortisman giderinde herhangi bir değişikliğe izin verilmez.'");
			MessageText = StrTemplate(MessageText, Selection.IntangibleAssetPresentation);
			Common.MessageToUser(MessageText, ThisObject, Path,, Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckDepreciation(NotCheckedAttributeArray, Cancel)

	RecipientTemplate = NStr("vi = 'Chưa điền trường ""Tổ chức nhận chi phí"" tại dòng ""%1"" trong danh sách ""Chi phí khấu hao"".';
							|ru = 'Не заполнено поле ""Организация-получатель расходов"" в строке ""%1"" списка ""Амортизационные расходы"".';
							|en = 'The ""Expense recipient company"" field is left empty in ""%1"" line of the ""Depreciation expenses"" list.'; fa = 'The ""Expense recipient company"" field is left empty in ""%1"" line of the ""Depreciation expenses"" list.';
							|it = 'The ""Expense recipient company"" field is left empty in ""%1"" line of the ""Depreciation expenses"" list.';
							|pl = 'The ""Expense recipient company"" field is left empty in ""%1"" line of the ""Depreciation expenses"" list.';
							|tr = '""Amortisman giderleri"" listesindeki ""%1"" satırında ""Giderlerin alıcısı olan iş yeri"" alanı doldurulmamış.'");
	
	For Each RowData In Depreciation Do

		If RowData.TransferExpensesToAnotherCompany
			And Not ValueIsFilled(RowData.CompanyRecipientOfExpenses) Then
				
			Path = CommonClientServer.PathToTabularSection("Depreciation", RowData.LineNumber, "CompanyRecipientOfExpenses");
			MessageText = StrTemplate(RecipientTemplate, RowData.LineNumber);
			Common.MessageToUser(MessageText, ThisObject, Path,, Cancel);
		EndIf;

	EndDo;
	
	If Depreciation.Count() < 2 Then
		NotCheckedAttributeArray.Add("Depreciation.ZoomRatio");
	EndIf;
	
EndProcedure

Procedure CheckReflectionInAccounting(Cancel)
	
	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, kayıtlarının birinde yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.PostInAccounting",, Cancel);
	EndIf;
	
	If FinancialAccountingGroupFlag 
		And (Not RecordInLocalAccounting Or Not RecordInManAccounting) Then
		
		QueryText = 
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	Catalog.IntangibleAssets AS IntangibleAssets
		|		
		|		LEFT JOIN InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
		|				&Date,
		|				Recorder <> &Ref
		|					AND Organization = &Organization
		|					AND IntangibleAsset IN (&ListOfIA)) AS AccountingProcedureAC
		|		ON (AccountingProcedureAC.IntangibleAsset = IntangibleAssets.Ref)
		|
		|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
		|				&Date,
		|				Recorder <> &Ref
		|					AND Organization = &Organization
		|					AND IntangibleAsset IN (&ListOfIA)) AS AccountingProcedureMA
		|		ON (AccountingProcedureMA.IntangibleAsset = IntangibleAssets.Ref)
		|
		|WHERE
		|	IntangibleAssets.Ref IN(&ListOfIA)
		|	AND (AccountingProcedureAC.BUState = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting)
		|			AND NOT &PostInAccounting
		|		OR AccountingProcedureAC.StateTa = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting)
		|			AND NOT &RecordInTA
		|		OR AccountingProcedureMA.State = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting)
		|			AND NOT &RecordInManAccounting)
		|";
		
		Query = New Query(QueryText);
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("Date", Date);
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("PostInAccounting", PostInAccounting);
		Query.SetParameter("RecordInTA", RecordInTA);
		Query.SetParameter("RecordInManAccounting", RecordInManAccounting);
		Query.SetParameter("ListOfIA", IA.UnloadColumn("IntangibleAsset"));
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
			MessageText = NStr("vi = 'Để thay đổi nhóm kế toán tài chính, cần phản ánh chứng từ trong tất cả các hệ thống kế toán nơi tài sản vô hình (chi phí R&D) đã được ghi nhận';
								|ru = 'Для изменения группы финансового учета необходимо отразить документ во всех учетах, в которых приняты нематериальные активы (расходы на НИОКР)';
								|en = 'To change the financial accounting group, record the document in all types of accounting where intangible assets (R&D expenses) are recognized'; fa = 'To change the financial accounting group, record the document in all types of accounting where intangible assets (R&D expenses) are recognized';
								|it = 'To change the financial accounting group, record the document in all types of accounting where intangible assets (R&D expenses) are recognized';
								|pl = 'To change the financial accounting group, record the document in all types of accounting where intangible assets (R&D expenses) are recognized';
								|tr = 'Finansal muhasebe grubunu değiştirmek için belgenin, maddi olmayan varlıkların (AR-GE giderleri) kabul edildiği tüm muhasebe türlerinde işlenmesi gerekir'");
			Common.MessageToUser(MessageText,, "Object.PostInAccounting");
		EndIf; 
		
	EndIf; 
	
EndProcedure
 
#EndRegion

#Region Other

Procedure BlockData_()
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.IntangibleAssetsAccountingProcedure");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = IA;
	LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
	LockItem.SetValue("Organization", Organization);
	
	If RecordInLocalAccounting Then
		
		LockItem = Block.Add("InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = IA;
		LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
		LockItem.SetValue("Organization", Organization);
		
		LockItem = Block.Add("InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = IA;
		LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
		LockItem.SetValue("Organization", Organization);
	EndIf;

	If RecordInManAccounting Then
		
		LockItem = Block.Add("InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = IA;
		LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
		LockItem.SetValue("Organization", Organization);
		
		LockItem = Block.Add("InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = IA;
		LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
		LockItem.SetValue("Organization", Organization);
	EndIf;
	
	Block.Lock();
	
EndProcedure

Function AuxiliaryAttributes()
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()))));
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndRegion

#EndIf
