
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	List = Items.ClassificationParameterType.ChoiceList;

	If GetFunctionalOption("UseABCXYZClassificationOfPartnersByGrossProfit") Then
		List.Add(Enums.TypesOfClassificationParameters.GrossProfit);
	EndIf;
	If GetFunctionalOption("UseABCXYZClassificationOfPartnersByRevenue") Then
		List.Add(Enums.TypesOfClassificationParameters.Revenue);
	EndIf;
	If GetFunctionalOption("UseABCXYZClassificationOfPartnersByNumberOfSales") Then
		List.Add(Enums.TypesOfClassificationParameters.Count);
	EndIf;
	
	If List.Count() = 0 Then
		CommonClientServer.MessageToUser(NStr(
			"vi = 'Chưa bật sử dụng kiểu phân loại ABC và XYZ bạn hàng nào.';
			|ru = 'Не включено использование ни одного типа ABC и XYZ классификации партнеров.';
			|en = 'No type of partner ABC and XYZ classification is enabled.'; fa = 'No type of partner ABC and XYZ classification is enabled.';
			|it = 'Non è stato attivato nessun tipo di classificazione dei partner ABC e XYZ.';
			|pl = 'Nie uwzględniono użycia żadnego rodzaju  ABC i XYZ klasyfikacji partnerów.';
			|tr = 'Herhangi bir iş ortağı ABC ve XYZ sınıflandırması tipinin kullanımı dahil değildir.'"));
		Cancel = True;
		Return;
	EndIf;

	ClassificationParameterType = List.Get(0).Value;
	Items.ClassificationParameterType.ReadOnly = (List.Count() <= 1);

	AnalysisOnTheDate = CurrentSessionDate();
	ErrorText = "";
	SetPeriods(ErrorText);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If PreviousSliceDate >= CurrentSliceDate Then
		MessageText = NStr("vi = 'Ngày mặt cắt trước phải nhỏ hơn ngày của mặt cắt hiện tại.';
							|ru = 'Дата предыдущего среза должна быть меньше даты текущего среза.';
							|en = 'The previous slice date should be earlier than the current slice date.'; fa = 'The previous slice date should be earlier than the current slice date.';
							|it = 'La data del segmento precedente deve essere antecedente alla data del segmento corrente.';
							|pl = 'Data poprzedniego przekroju musi być mniejsza niż data bieżącego przekroju.';
							|tr = 'Önceki kesit tarihi, geçerli kesitin tarihinden önce olmalıdır.'");
		CommonClientServer.MessageToUser(MessageText,,"PreviousSliceDate");
		
		Cancel = True;
	Else
		If Not ValueIsFilled(SliceDate(PreviousSliceDate)) Then
			MessageText = NStr("vi = 'Không tồn tại mặt cắt ngày %Date%.';
								|ru = 'Среза на %Date% не существует.';
								|en = 'Slice for %Date% does not exist.'; fa = 'Slice for %Date% does not exist.';
								|it = 'Non esiste nessun segmento per la %Date%.';
								|pl = 'Przekroju na %Date% nie istnieje.';
								|tr = '%Date% için kesit yoktur.'");
			MessageText = StrReplace(MessageText, "%Date%", Format(PreviousSliceDate, "DLF=DD"));
			CommonClientServer.MessageToUser(MessageText,,"PreviousSliceDate");
		
			Cancel = True;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(ClassificationParameterType) Then
		Cancel = True;
		CommonClientServer.MessageToUser(NStr("vi = 'Cần chỉ ra kiểu tham số phân loại';
												|ru = 'Необходимо указать тип параметра классификации';
												|en = 'Specify classification parameter type'; fa = 'Specify classification parameter type';
												|it = 'È necessario indicare il tipo di parametro della classificazione';
												|pl = 'Należy podać typ parametru klasyfikacji';
												|tr = 'Sınıflandırma parametre türünü belirtmeniz gerekmektedir'"),,"ClassificationParameterType");
	EndIf;
	
	If Not ValueIsFilled(CurrentSliceDate) Then
		Cancel = True;
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền ngày của mặt cắt hiện tại. Giá trị này được điền tự động khi chọn ngày phân tích bởi các giá trị gần nhất của kỳ tính phân loại ABC và XYZ.';
												|ru = 'Не заполнена дата текущего среза. Данное значение заполняется автоматически при выборе даты анализа, ближайшими значением периода расчета ABC и XYZ классификации.';
												|en = 'The current slice date is not filled in. This value is filled in automatically with the nearest values of the period of ABC and XYZ classification calculation when selecting an analysis date.'; fa = 'The current slice date is not filled in. This value is filled in automatically with the nearest values of the period of ABC and XYZ classification calculation when selecting an analysis date.';
												|it = 'La data del segmento corrente non è compilata. Il valore corrente viene compilato automaticamente quando si sceglie la data dell''analisi, con il valore più vicino del periodo della contabilità con classificazione ABC e XYZ.';
												|pl = 'Data bieżącego przekroju nie jest wypełniona. Ta wartość jest automatycznie wypełniana po wybraniu daty analizy, przez najbliższą wartość z okresu obliczeniowego klasyfikacji ABC i XYZ.';
												|tr = 'Geçerli kesitin tarihi doldurulmadı. Mevcut değer, analiz tarihi, hesaplama periyodu ABC ve XYZ sınıflandırmasının en yakın değeri seçildiğinde otomatik olarak doldurulmaktadır.'"),,"CurrentSliceDate");
	EndIf;
	
	If Not ValueIsFilled(PreviousSliceDate) Then
		Cancel = True;
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền ngày của mặt cắt trước.';
												|ru = 'Не заполнена дата предыдущего среза.';
												|en = 'The previous slice date is required.'; fa = 'The previous slice date is required.';
												|it = 'Non è compilata la data del segmento precedente.';
												|pl = 'Data poprzedniego przekroju nie jest wypełniona.';
												|tr = 'Önceki kesitin tarihi doldurulmadı.'"),,"PreviousSliceDate");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PreviousSliceDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ClearMessages();
	CheckFilling();
EndProcedure

&AtClient
Procedure AnalysisOnTheDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ErrorText = "";
	SetPeriods(ErrorText);
	If ErrorText <> "" Then
		ClearMessages();
		CommonClientServer.MessageToUser(ErrorText,,"AnalysisOnTheDate");
	EndIf;
	
EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)

	StandardProcessing = False;

	Details.Insert("CurrentPeriod",             CurrentSliceDate);
	Details.Insert("PreviousPeriod",             PreviousSliceDate);
	Details.Insert("ClassificationParameterType", ClassificationParameterType);
	
	UserSettings = GetCustomDecryptionReportSettings(Details.NameDecryption);
	
	OpenForm(
		Details.NameDecryption,
		New Structure("GenerateOnOpen, Details, UserSettings", True, Details, UserSettings),
		ThisForm, True);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateReport(Command)
	
	ClearMessages();
	If CheckFilling() Then
		OutputMatrices();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function GetCustomDecryptionReportSettings(ReportFormName)
	
	If ReportFormName = "Report.ChangeABCXYZClassificationOfCustomers.Form" Then
		Schema = Reports.ChangeABCXYZClassificationOfCustomers.GetTemplate("MainDataCompositionSchema");
	Else
		Schema = Reports.ABCXYZCustomersAllocation.GetTemplate("MainDataCompositionSchema");
	EndIf;
	Source = New DataCompositionAvailableSettingsSource(Schema);
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(Source);
	UserSettings = Composer.UserSettings;
	
	Return UserSettings;
EndFunction

&AtServerNoContext
Function GETParameterName(ClassValue)

	If ClassValue = Enums.ABCClassification.AClass Then
		ParameterName = "A";
	ElsIf ClassValue = Enums.ABCClassification.BClass Then
		ParameterName = "B";
	ElsIf ClassValue = Enums.ABCClassification.CClass Then
		ParameterName = "C";
	ElsIf ClassValue = Enums.ABCClassification.NotClassified Then
		ParameterName = "_";
	ElsIf ClassValue = Enums.ABCClassification.EmptyRef() Then
		ParameterName = "P";
	ElsIf ClassValue = Enums.XYZClassification.XClass Then
		ParameterName = "X";
	ElsIf ClassValue = Enums.XYZClassification.YClass Then
		ParameterName = "Y";
	ElsIf ClassValue = Enums.XYZClassification.ZClass Then
		ParameterName = "Z";
	ElsIf ClassValue = Enums.XYZClassification.NotClassified Then
		ParameterName = "L";
	ElsIf ClassValue = Enums.XYZClassification.EmptyRef() Then
		ParameterName = "P";
	EndIf;

	Return ParameterName;

EndFunction

&AtServerNoContext
Function GetClassDescription(ClassValue)

	If ClassValue = Enums.ABCClassification.EmptyRef() Then
		Return NStr("vi = 'khách hàng tiềm năng(ABC)';
					|ru = 'потенциальный клиент(ABC)';
					|en = 'potential customer (ABC)'; fa = 'potential customer (ABC)';
					|it = 'potenziale cliente (ABC)';
					|pl = 'potencjalny klient(ABC)';
					|tr = 'potansiyel müşteri(ABC)'");
	ElsIf ClassValue = Enums.ABCClassification.NotClassified Then
		Return NStr("vi = 'khách hàng bị mất(ABC)';
					|ru = 'потерянный клиент(ABC)';
					|en = 'lost customer (ABC)'; fa = 'lost customer (ABC)';
					|it = 'cliente perso (ABC)';
					|pl = 'utracony klient(ABC)';
					|tr = 'kaybedilen müşteri(ABC)'");
	ElsIf ClassValue = Enums.XYZClassification.EmptyRef() Then
		Return NStr("vi = 'khách hàng tiềm năng(XYZ)';
					|ru = 'потенциальный клиент(XYZ)';
					|en = 'potential customer (XYZ)'; fa = 'potential customer (XYZ)';
					|it = 'potenziale cliente (XYZ)';
					|pl = 'potencjalny klient(XYZ)';
					|tr = 'potansiyel müşteri(XYZ)'");
	ElsIf ClassValue = Enums.XYZClassification.NotClassified Then
		Return NStr("vi = 'khách hàng bị mất(XYZ)';
					|ru = 'потерянный клиент(XYZ)';
					|en = 'lost customer (XYZ)'; fa = 'lost customer (XYZ)';
					|it = 'cliente perso (XYZ)';
					|pl = 'utracony klient(XYZ)';
					|tr = 'kaybedilen müşteri(XYZ)'");
	Else
		Return String(ClassValue);
	EndIf;

EndFunction

&AtServerNoContext
Procedure FillParameters_(Parameter1, Parameter2, NumberOfCustomers, Area)

	ParameterType1 = TypeOf(Parameter1);
	Changes = (ParameterType1 = TypeOf(Parameter2));
	ParameterName = GETParameterName(Parameter1) + GETParameterName(Parameter2);
	NameOfDecryptionParameter = ?(Changes, "m", "d");
	NameOfDecryptionParameter = NameOfDecryptionParameter + ParameterName;
	Try
	   Area.Parameters[ParameterName] = NumberOfCustomers;	
	Except
	   Return;
	EndTry;	

	If Changes Then
		NameDecryption = "Report.ChangeABCXYZClassificationOfCustomers.Form";
		If ParameterType1 = Type("EnumRef.ABCClassification") Then
			FilterFields = New Structure("PreviousABC, CurrentABC", Parameter1, Parameter2);
			ListTitle = NStr("vi = 'Chuyển từ %Parameter1% sang %Parameter2%';
							|ru = 'Перешли из %Parameter1% в %Parameter2%';
							|en = 'Transferred from %Parameter1% to %Parameter2%'; fa = 'Transferred from %Parameter1% to %Parameter2%';
							|it = 'Passaggio dal %Parameter1% al %Parameter2%';
							|pl = 'Przeszły z %Parameter1% do %Parameter2%';
							|tr = '%Parameter1% üzerinden %Parameter2% içine geçildi'");
		Else
			FilterFields = New Structure("PreviousXYZ, CurrentXYZ", Parameter1, Parameter2);
			ListTitle = NStr("vi = 'Chuyển từ %Parameter1% sang %Parameter2%';
							|ru = 'Перешли из %Parameter1% в %Parameter2%';
							|en = 'Transferred from %Parameter1% to %Parameter2%'; fa = 'Transferred from %Parameter1% to %Parameter2%';
							|it = 'Passaggio dal %Parameter1% al %Parameter2%';
							|pl = 'Przeszły z %Parameter1% do %Parameter2%';
							|tr = '%Parameter1% üzerinden %Parameter2% içine geçildi'");
		EndIf;
	Else
		NameDecryption = "Report.ABCXYZCustomersAllocation.Form";
		FilterFields = New Structure("ABCClass, XYZClass", Parameter1, Parameter2);
		ListTitle = NStr("vi = 'Đưa vào %Parameter1%, %Parameter2%';
						|ru = 'Отнесены к %Parameter1%, %Parameter2%';
						|en = 'Referred to %Parameter1%, %Parameter2%'; fa = 'Referred to %Parameter1%, %Parameter2%';
						|it = 'Assegnati al %Parameter1%, %Parameter2%';
						|pl = 'Przypisane do %Parameter1%, %Parameter2%';
						|tr = '%Parameter1%, %Parameter2% üzerine tahsis edildi'");
	EndIf;

	ListTitle = StrReplace(ListTitle, "%Parameter1%", GetClassDescription(Parameter1));
	ListTitle = StrReplace(ListTitle, "%Parameter2%", GetClassDescription(Parameter2));
	Try
		Area.Parameters[NameOfDecryptionParameter] = New Structure(
		"NameDecryption, Title, Filter", NameDecryption, ListTitle, FilterFields);
	Except
		Return;
	EndTry;

EndProcedure

&AtServerNoContext
Function SliceDate(WorkingDate)

	Query = New Query(
		"SELECT ALLOWED
		|	MAX(ABCXYZCustomerClassificationSliceLast.Period) AS Period
		|FROM
		|	InformationRegister.ABCXYZCustomerClassification.SliceLast(&SliceDate, ) AS ABCXYZCustomerClassificationSliceLast");
	Query.SetParameter("SliceDate", WorkingDate - 1);
	Selection = Query.Execute().Select();
	Selection.Next();
	Return Selection.Period;

EndFunction

&AtServer
Procedure SetPeriods(ErrorText)

	ClassificationPeriod = TMCommonUseClientServer.ExtendedPeriod(
			AnalysisOnTheDate, Constants.PeriodOfABCClassificationOfPartners.Get(), -Constants.NumberOfPeriodsOfABCClassificationOfPartners.Get());
	Query = New Query(
		"SELECT ALLOWED DISTINCT TOP 2
		|	ABCXYZCustomerClassification.Period AS Period
		|FROM
		|	InformationRegister.ABCXYZCustomerClassification AS ABCXYZCustomerClassification
		|WHERE
		|	ABCXYZCustomerClassification.Period <= &AnalysisOnTheDate
		|
		|ORDER BY
		|	Period DESC");
	Query.SetParameter("AnalysisOnTheDate", AnalysisOnTheDate);
	Selection = Query.Execute();

	If Not Selection.IsEmpty() Then

		Selection = Selection.Select();
		Selection.Next();
		CurrentSliceDate = Selection.Period;
		If Selection.Next() Then
			PreviousSliceDate = Selection.Period;
		Else
			ErrorText = NStr("vi = 'Vào ngày %Date% không có mặt cắt trước.';
							|ru = 'На %Date% отсутствует предыдущий срез.';
							|en = 'Previous slice is missing on %Date%.'; fa = 'Previous slice is missing on %Date%.';
							|it = 'Alla %Date% manca il segmento precedente.';
							|pl = 'Na dzień %Date% brak poprzedniego przekroju.';
							|tr = '%Date% içinde kesit bulunmamaktadır.'");
			ErrorText = StrReplace(ErrorText, "%Date%", Format(AnalysisOnTheDate, "DLF=DD"));
			PreviousSliceDate = '00010101';
		EndIf;

		If ValueIsFilled(ClassificationParameterType) Then
			OutputMatrices();
		EndIf;
	Else
		ErrorText = NStr("vi = 'Vào ngày %Date% không có phân loại.';
						|ru = 'На %Date% классификация отсутствует.';
						|en = 'Classification is missing on %Date%.'; fa = 'Classification is missing on %Date%.';
						|it = 'Alla %Date% manca la classificazione precedente.';
						|pl = 'Na dzień %Date% brak klasyfikacji.';
						|tr = '%Date% içinde sınıflandırma bulunmamaktadır.'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(AnalysisOnTheDate, "DLF=DD"));
	EndIf;

EndProcedure

&AtServer
Procedure OutputMatrices()

	Questions					= 0;
	Template					= Reports.BCGMatrix.GetTemplate("Matrixes");
	AreaOfMatrices			= Template.GetArea("Matrixes");
	ScopeOfChanges		= Template.GetArea("Changes");
	PotentialCustomers	= 0 ;

	Query = New Query(
		"SELECT ALLOWED
		|	ABCXYZCustomerClassificationSliceLast.Partner AS Partner,
		|	ABCXYZCustomerClassificationSliceLast.Class AS Class
		|INTO CurrentABC
		|FROM
		|	InformationRegister.ABCXYZCustomerClassification.SliceLast(&CurrentPeriod, ) AS ABCXYZCustomerClassificationSliceLast
		|WHERE
		|	ABCXYZCustomerClassificationSliceLast.ClassificationType = VALUE(Enum.TypesOfClassification.ABC)
		|	AND ABCXYZCustomerClassificationSliceLast.ClassificationParameterType = &ClassificationParameterType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ABCXYZCustomerClassificationSliceLast.Partner AS Partner,
		|	ABCXYZCustomerClassificationSliceLast.Class AS Class
		|INTO PreviousABC
		|FROM
		|	InformationRegister.ABCXYZCustomerClassification.SliceLast(&PreviousPeriod, ) AS ABCXYZCustomerClassificationSliceLast
		|WHERE
		|	ABCXYZCustomerClassificationSliceLast.ClassificationType = VALUE(Enum.TypesOfClassification.ABC)
		|	AND ABCXYZCustomerClassificationSliceLast.ClassificationParameterType = &ClassificationParameterType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ABCXYZCustomerClassificationSliceLast.Partner AS Partner,
		|	ABCXYZCustomerClassificationSliceLast.Class AS Class
		|INTO CurrentXYZ
		|FROM
		|	InformationRegister.ABCXYZCustomerClassification.SliceLast(&CurrentPeriod, ) AS ABCXYZCustomerClassificationSliceLast
		|WHERE
		|	ABCXYZCustomerClassificationSliceLast.ClassificationType = VALUE(Enum.TypesOfClassification.XYZ)
		|	AND ABCXYZCustomerClassificationSliceLast.ClassificationParameterType = &ClassificationParameterType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ABCXYZCustomerClassificationSliceLast.Partner AS Partner,
		|	ABCXYZCustomerClassificationSliceLast.Class AS Class
		|INTO PreviousXYZ
		|FROM
		|	InformationRegister.ABCXYZCustomerClassification.SliceLast(&PreviousPeriod, ) AS ABCXYZCustomerClassificationSliceLast
		|WHERE
		|	ABCXYZCustomerClassificationSliceLast.ClassificationType = VALUE(Enum.TypesOfClassification.XYZ)
		|	AND ABCXYZCustomerClassificationSliceLast.ClassificationParameterType = &ClassificationParameterType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Partners.Ref AS Partner
		|INTO ClassifiedPartners
		|FROM
		|	Catalog.Partners AS Partners
		|WHERE
		|	Partners.Ref IN
		|			(SELECT
		|				PreviousABC.Partner
		|			FROM
		|				PreviousABC AS PreviousABC
		|		
		|			UNION ALL
		|		
		|			SELECT
		|				PreviousXYZ.Partner
		|			FROM
		|				PreviousXYZ AS PreviousXYZ
		|		
		|			UNION ALL
		|		
		|			SELECT
		|				CurrentABC.Partner
		|			FROM
		|				CurrentABC AS CurrentABC
		|		
		|			UNION ALL
		|		
		|			SELECT
		|				CurrentXYZ.Partner
		|			FROM
		|				CurrentXYZ AS CurrentXYZ)
		|	AND (NOT Partners.DeletionMark) AND (NOT Partners.Predefined)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(CurrentXYZ.Class, VALUE(Enum.XYZClassification.EmptyRef)) AS CurrentXYZ,
		|	ISNULL(CurrentABC.Class, VALUE(Enum.ABCClassification.EmptyRef)) AS CurrentABC,
		|	ISNULL(PreviousXYZ.Class, VALUE(Enum.XYZClassification.EmptyRef)) AS PreviousXYZ,
		|	ISNULL(PreviousABC.Class, VALUE(Enum.ABCClassification.EmptyRef)) AS PreviousABC,
		|	ClassifiedPartners.Partner AS Partner
		|FROM
		|	ClassifiedPartners AS ClassifiedPartners
		|		LEFT JOIN PreviousABC AS PreviousABC
		|		ON ClassifiedPartners.Partner = PreviousABC.Partner
		|		LEFT JOIN CurrentABC AS CurrentABC
		|		ON ClassifiedPartners.Partner = CurrentABC.Partner
		|		LEFT JOIN PreviousXYZ AS PreviousXYZ
		|		ON ClassifiedPartners.Partner = PreviousXYZ.Partner
		|		LEFT JOIN CurrentXYZ AS CurrentXYZ
		|		ON ClassifiedPartners.Partner = CurrentXYZ.Partner
		|WHERE
		|	(NOT ClassifiedPartners.Partner.DeletionMark)
		|TOTALS
		|	COUNT(DISTINCT Partner)
		|BY
		|	CurrentXYZ,
		|	CurrentABC,
		|	PreviousXYZ,
		|	PreviousABC");
	Query.SetParameter("CurrentPeriod", CurrentSliceDate);
	Query.SetParameter("PreviousPeriod", PreviousSliceDate);
	Query.SetParameter("ClassificationParameterType", ClassificationParameterType);

	QueryResult = Query.Execute();

	// fill in BCG, A-Z distribution and XYZ changes
	SamplingCurXYZ = QueryResult.Select(QueryResultIteration.ByGroupsWithHierarchy);
	While SamplingCurXYZ.Next() Do

		If SamplingCurXYZ.CurrentXYZ = Enums.XYZClassification.NotClassified Then
			AreaOfMatrices.Parameters.Lost_ = SamplingCurXYZ.Partner;
			NameDecryption = "Report.ABCXYZCustomersAllocation.Form";
			ListTitle = NStr("vi = 'Khách hàng bị mất';
							|ru = 'Потерянные клиенты';
							|en = 'Lost customers'; fa = 'Lost customers';
							|it = 'Clienti persi';
							|pl = 'Utracone klienci';
							|tr = 'Kaybedilen müşteriler'");
			FilterFields = New Structure("XYZClass", Enums.XYZClassification.NotClassified);
			AreaOfMatrices.Parameters.dLost_ = New Structure(
				"NameDecryption, Title, Filter", NameDecryption, ListTitle, FilterFields);
		ElsIf SamplingCurXYZ.CurrentXYZ = Enums.XYZClassification.EmptyRef() Then
			AreaOfMatrices.Parameters.Potential_ = SamplingCurXYZ.Partner;
			
			PotentialCustomers = SamplingCurXYZ.Partner;
			
			NameDecryption = "Report.ABCXYZCustomersAllocation.Form";
			ListTitle = NStr("vi = 'Khách hàng tiềm năng';
							|ru = 'Потенциальные клиенты';
							|en = 'Potential customers'; fa = 'Potential customers';
							|it = 'Potenziali clienti';
							|pl = 'Potencjalni klienci';
							|tr = 'Potansiyel müşteriler'");
			FilterFields = New Structure("XYZClass", Enums.XYZClassification.EmptyRef());
			AreaOfMatrices.Parameters.dPotential_ = New Structure(
				"NameDecryption, Title, Filter", NameDecryption, ListTitle, FilterFields);
		Else
			// fill in the A-Z distribution
			SamplingCurABC = SamplingCurXYZ.Select(QueryResultIteration.ByGroupsWithHierarchy);
			While SamplingCurABC.Next() Do
				FillParameters_(
					SamplingCurABC.CurrentABC, SamplingCurABC.CurrentXYZ,
					SamplingCurABC.Partner, AreaOfMatrices);
				If Not((SamplingCurABC.CurrentABC = Enums.ABCClassification.AClass
						And SamplingCurABC.CurrentXYZ = Enums.XYZClassification.XClass)
						Or
						(SamplingCurABC.CurrentABC = Enums.ABCClassification.AClass
						And SamplingCurABC.CurrentXYZ = Enums.XYZClassification.ZClass)
						Or
						(SamplingCurABC.CurrentABC = Enums.ABCClassification.CClass
						And SamplingCurABC.CurrentXYZ = Enums.XYZClassification.XClass)) Then
					Questions = Questions + SamplingCurABC.Partner;
				EndIf;
			EndDo; //fill in the A-Z distribution
		EndIf;

		// fill in XYZ changes
		If PreviousSliceDate <> '00010101' Then
			SamplingFromXYZ = SamplingCurXYZ.Select(
				QueryResultIteration.ByGroupsWithHierarchy, "PreviousXYZ");
			While SamplingFromXYZ.Next() Do
				If Not ValueIsFilled(SamplingFromXYZ.CurrentXYZ) Then
					Continue;
				EndIf;

				FillParameters_(
					?(ValueIsFilled(SamplingFromXYZ.PreviousXYZ),
						SamplingFromXYZ.PreviousXYZ, Enums.XYZClassification.EmptyRef()
					),
					?(ValueIsFilled(SamplingFromXYZ.CurrentXYZ),
							SamplingFromXYZ.CurrentXYZ, Enums.XYZClassification.EmptyRef()
					),
					SamplingFromXYZ.Partner, ScopeOfChanges);
			EndDo; //fill in XYZ changes
		EndIf; //fill in XYZ changes

		AreaOfMatrices.Parameters.Questions = Questions;
		NameDecryption = "Report.ABCXYZCustomersAllocation.Form";
		AreaOfMatrices.Parameters.dQuestions = New Structure(
			"NameDecryption, Title, Questions",
			NameDecryption, NStr("vi = 'Đưa vào thể loại BCG ""câu hỏi""';
								|ru = 'Отнесены к категории BCG ""вопросы""';
								|en = 'Referred to the BCG ""questions"" category'; fa = 'Referred to the BCG ""questions"" category';
								|it = 'Attribuiti alla categoria BCG ""domande""';
								|pl = 'Przypisane do kategorii BCG ""pytania""';
								|tr = 'BCG ""sorular"" olarak kategorize edildi'"), True);

	EndDo; //fill in BCG, A-Z distribution and XYZ changes

	// output the area of matrices
	Result.Clear();
	Result.Put(AreaOfMatrices);
	
	If PotentialCustomers = 0 Then
		Result.DeleteArea(Result.Areas.Potential_, SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	
	// fill in the changes ABC and output the area of changes
	If PreviousSliceDate <> '00010101' Then
		SamplingCurABC = QueryResult.Select(
			QueryResultIteration.ByGroupsWithHierarchy, "CurrentABC");
		While SamplingCurABC.Next() Do
			If Not ValueIsFilled(SamplingCurABC.CurrentABC) Then
				Continue;
			EndIf;
			SamplingFromABC = SamplingCurABC.Select(
				QueryResultIteration.ByGroupsWithHierarchy, "PreviousABC");
			While SamplingFromABC.Next() Do
				FillParameters_(
					?(ValueIsFilled(SamplingFromABC.PreviousABC),
						SamplingFromABC.PreviousABC,
						Enums.ABCClassification.EmptyRef()
					),
					?(ValueIsFilled(SamplingFromABC.CurrentABC),
							SamplingFromABC.CurrentABC,
							Enums.ABCClassification.EmptyRef()
					),
					SamplingFromABC.Partner, ScopeOfChanges);
			EndDo;
		EndDo;

		Result.Put(ScopeOfChanges);
	EndIf; //fill in the changes ABC and output the area of changes

EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_AnalysisOnTheDate" Then
		AnalysisOnTheDateOnChange(Items.AnalysisOnTheDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_PreviousSliceDate" Then
		PreviousSliceDateOnChange(Items.PreviousSliceDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
