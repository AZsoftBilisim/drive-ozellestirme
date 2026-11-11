
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	IntangibleAssetsAmortizationChargeLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocumentBeforeFillingItOut();
	
	IntangibleAssetsAmortizationChargeLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	CheckDuplicates(Cancel);
	
	IntangibleAssetsAmortizationChargeLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	IntangibleAssetsAmortizationChargeLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	IntangibleAssetsAmortizationChargeLocalization.OnWrite(ThisObject, Cancel);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	If Not AdditionalProperties.Property("TempTablesManager") Then
		CalculateDepreciation(Cancel);
	EndIf;
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel, AddlParameters);
	
	IntangibleAssetsAmortizationChargeLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	CreateTaskDepreciationOfIaWhenCancelingEvent();
	
	IntangibleAssetsAmortizationChargeLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocumentBeforeFillingItOut()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	PackageNumber = Documents.IntangibleAssetsAmortizationCharge2_4.DefaultPackageNumber(Organization);
	
EndProcedure

Procedure CheckDuplicates(Cancel)

	If Not ValueIsFilled(Organization) 
		Or Not ValueIsFilled(PackageNumber) 
		Or Not ValueIsFilled(Date) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	IntangibleAssetsAmortizationCharge2_4.Ref
	|FROM
	|	Document.IntangibleAssetsAmortizationCharge2_4 AS IntangibleAssetsAmortizationCharge2_4
	|WHERE
	|	IntangibleAssetsAmortizationCharge2_4.Ref <> &Ref
	|	AND IntangibleAssetsAmortizationCharge2_4.Posted
	|	AND IntangibleAssetsAmortizationCharge2_4.Organization = &Organization
	|	AND IntangibleAssetsAmortizationCharge2_4.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND IntangibleAssetsAmortizationCharge2_4.PackageNumber = &PackageNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("PackageNumber", PackageNumber);
	Query.SetParameter("BegOfMonth", BegOfMonth(Date));
	Query.SetParameter("EndOfMonth", EndOfMonth(Date));
	Query.SetParameter("Ref", Ref);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		TextTemplate1 = NStr("vi = 'Trong %1 đã có chứng từ được kết chuyển đối với doanh nghiệp và số gói chứng từ đã chọn.
                             |Cần chọn số gói khác hoặc sử dụng đóng tháng.';
                             |ru = 'За %1 уже есть проведенный документ для выбранной организации и номера пакета.
                             |Необходимо выбрать другой номер пакета или воспользоваться закрытием месяца.';
                             |en = 'There is a posted document for the selected company and package number for %1.
                             |Select another package number or use month-end closing.'; fa = 'There is a posted document for the selected company and package number for %1.
                             |Select another package number or use month-end closing.';
                             |it = 'Per %1 esiste già un documento registrato per la società e il numero di pacchetto selezionati.
                             |È necessario selezionare un numero di pacchetto diverso o approfittare della chiusura del mese.';
                             |pl = 'Za %1 jest obecny już zatwierdzony dokument wybranej firmy i numer pakietu. 
                             |Należy wybrać inny numer pakietu lub skorzystać z zamknięcia miesiąca.';
                             |tr = 'Seçilen iş yeri ve paket numarası için %1 kapsamında zaten kaydedilen belge mevcut.
                             |Başka bir paket numarası seçmeniz veya ay sonu kapanışı kullanmanız gerekmektedir.'");
		MessageText = StrTemplate(TextTemplate1, Format(Date, NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
																	|ru = 'ДФ=''ММММ гггг ""г.""''';
																	|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																	|it = 'ДФ=''ММММ гггг ""a.""''';
																	|pl = 'DF=''ММММ yyyy ""r.""''';
																	|tr = 'DF=''MMMM yyyy ""yıl.""'''")));
		CommonClientServer.MessageToUser(MessageText, ThisObject, "PackageNumber",, Cancel); 
	EndIf; 
	
EndProcedure

Procedure CreateTaskDepreciationOfIaWhenCancelingEvent()

	If InformationRegisters.JobsForCalculatingIntangibleAssetAmortization.CalculationIsRequired(Organization, BegOfMonth(Date)) Then
		InformationRegisters.JobsForCalculatingIntangibleAssetAmortization.CreateRegisterEntry(BegOfMonth(Date), Ref, Organization, PackageNumber);
	EndIf;
	
EndProcedure

Procedure CalculateDepreciation(Cancel)

	CalculationParameters = IntangibleAssetAmortizationCalculation.ExecutionParameters();
	CalculationParameters.Period = Date;
	CalculationParameters.CompaniesList = CommonClientServer.ValueInArray(Organization);
	CalculationParameters.WriteData = False;
	CalculationParameters.RegisterErrors = False;
	
	NewPackage = CalculationParameters.DepreciationPackages.Add();
	NewPackage.Organization = Organization;
	NewPackage.PackageNumber = PackageNumber;
	
	Documents.IntangibleAssetsAmortizationCharge2_4.CalculateDepreciation(CalculationParameters);
	
	AdditionalProperties.Insert("TempTablesManager", CalculationParameters.TempTablesManager);
	
	If CalculationParameters.HasErrors Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
