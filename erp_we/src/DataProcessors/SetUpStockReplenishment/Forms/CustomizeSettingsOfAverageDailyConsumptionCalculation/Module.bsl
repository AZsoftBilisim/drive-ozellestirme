
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CalculationPeriod                 = Constants.PeriodOfGoodsLimitationCalculation.Get();
	NumberOfCalculationPeriods     = Constants.NumberOfCommercialRestrictionCalculationPeriods.Get();
	SeasonalFluctuationsRegistrationOption = Constants.SeasonalFluctuationsRegistrationOption.Get();
	
	ConfigureFormByRightsAndFunctionalOptions();
	SetLockBasedOnSeasonalCoefficients();
	
	SetHintHeaders(ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet"
		And (Source = "UseSeasonalIndexes" Or Source = "UseProductCategories")Then
		
		ConfigureFormByRightsAndFunctionalOptions();
		SetHintHeaders(ThisForm);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodOfGoodsLimitationCalculationOnChange(Item)
	
	ThisIsYear = CalculationPeriod = PredefinedValue("Enum.Periodicity.Year");
	If ThisIsYear Or ThePreviousCalculationPeriodWasAYear Then
		SetLockBasedOnSeasonalCoefficients();
	EndIf;
	
	SetHintHeaders(ThisForm);
	
EndProcedure

&AtClient
Procedure NumberOfCommercialRestrictionCalculationPeriodsOnChange(Item)
	SetHintHeaders(ThisForm);
EndProcedure

&AtClient
Procedure DontConsiderOnChange(Item)
	SetHintHeaders(ThisForm);
EndProcedure

&AtClient
Procedure BySeasonalIndexesOnChange(Item)
	SetHintHeaders(ThisForm);
EndProcedure

&AtClient
Procedure BySamePeriodOfLastYearOnChange(Item)
	SetHintHeaders(ThisForm);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If CheckFilling() Then
		
		SaveParameters();
		
		ReturnCode = New Structure;
		ReturnCode.Insert("PeriodOfGoodsLimitationCalculation", CalculationPeriod);
		ReturnCode.Insert("NumberOfCommercialRestrictionCalculationPeriods", NumberOfCalculationPeriods);
		ReturnCode.Insert("SeasonalFluctuationsRegistrationOption", SeasonalFluctuationsRegistrationOption);
		
		Notify("ClosingForm_", , ThisForm);
		Close(ReturnCode);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ConfigureFormByRightsAndFunctionalOptions()
	
	UseSeasonalIndexes = GetFunctionalOption("UseSeasonalIndexes");
	Items.BySeasonalIndexes.Enabled                   = UseSeasonalIndexes
		And CalculationPeriod <> Enums.Periodicity.Year;
	Items.CommentOnAvailabilityOfSeasonalCoefficients.Visible = Not UseSeasonalIndexes;
	
	UseProductCategories = GetFunctionalOption("UseProductCategories");
	Items.BySamePeriodOfLastYear.Enabled = UseProductCategories;
	Items.ReviewTheAccessibilityOfAPPG.Visible          = Not UseProductCategories;
	
	SeasonalIndexesAreAvailable = UseSeasonalIndexes
		And AccessRight("View", Metadata.InformationRegisters.SeasonalIndexes);
	
	// We will hide the incorrect option from the user
	If (SeasonalFluctuationsRegistrationOption = Enums.SeasonalFluctuationsAccounting.BySeasonalIndexes
		And Not UseSeasonalIndexes)
		Or (SeasonalFluctuationsRegistrationOption = Enums.SeasonalFluctuationsAccounting.BySamePeriodOfLastYear
		And Not UseProductCategories) Then
		SeasonalFluctuationsRegistrationOption = Enums.SeasonalFluctuationsAccounting.DontConsider;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetHintHeaders(Form)
	
	If Form.CalculationPeriod = PredefinedValue("Enum.Periodicity.Day") Then
		CurrentPeriod     = NStr("vi = 'ngày hiện tại';
								|ru = 'текущий день';
								|en = 'current day'; fa = 'current day';
								|it = 'giorno corrente';
								|pl = 'bieżący dzień';
								|tr = 'bu gün'");
		SimilarPeriod = NStr("vi = 'tương tự như ngày nay năm ngoái';
							|ru = 'аналогичный текущему день прошлого года';
							|en = 'day of the last year similar to the current day'; fa = 'day of the last year similar to the current day';
							|it = 'il giorno dell''anno scorso analogo a quello corrente';
							|pl = 'podobny do bieżącego dnia zeszłego roku';
							|tr = 'geçen yılın şimdiki gününe benzer'");
	ElsIf Form.CalculationPeriod = PredefinedValue("Enum.Periodicity.Week") Then
		CurrentPeriod     = NStr("vi = 'tuần hiện tại';
								|ru = 'текущая неделя';
								|en = 'current week'; fa = 'current week';
								|it = 'la settimana corrente';
								|pl = 'bieżący tydzień';
								|tr = 'bu hafta'");
		SimilarPeriod = NStr("vi = 'tương tự như tuần hiện tại của năm ngoái';
							|ru = 'аналогичная текущей неделя прошлого года';
							|en = 'week of the last year similar to the current week'; fa = 'week of the last year similar to the current week';
							|it = 'la settimana dell''anno scorso analoga a quella corrente';
							|pl = 'podobny do bieżącego tygodnia zeszłego roku';
							|tr = 'geçen yılın bu haftasına benzer'");
	ElsIf Form.CalculationPeriod = PredefinedValue("Enum.Periodicity.TenDays") Then
		CurrentPeriod     = NStr("vi = 'mười ngày hiện tại';
								|ru = 'текущая декада';
								|en = 'current ten-day period'; fa = 'current ten-day period';
								|it = 'decade corrente';
								|pl = 'obecna dekada';
								|tr = 'bu on yıl'");
		SimilarPeriod = NStr("vi = 'tương tự như mười ngày hiện tại của năm ngoái';
							|ru = 'аналогичная текущей декада прошлого года';
							|en = 'ten-day period of the last year similar to the current ten-day period'; fa = 'ten-day period of the last year similar to the current ten-day period';
							|it = 'la decade dell''anno scorso analoga a quella corrente';
							|pl = 'podobna do obecnej dekada ubiegłego roku';
							|tr = 'geçen yılın şu anki on yılına benzer'");
	ElsIf Form.CalculationPeriod = PredefinedValue("Enum.Periodicity.Month") Then
		CurrentPeriod     = NStr("vi = 'tháng hiện tại';
								|ru = 'текущий месяц';
								|en = 'current month'; fa = 'current month';
								|it = 'mese corrente';
								|pl = 'obecny miesiąc';
								|tr = 'bu ay'");
		SimilarPeriod = NStr("vi = 'tương tự như tháng hiện tại của năm ngoái';
							|ru = 'аналогичный текущему месяц прошлого года';
							|en = 'month of the last year similar to the current month'; fa = 'month of the last year similar to the current month';
							|it = 'il mese dell''anno scorso analogo a quello corrente';
							|pl = 'podobny do bieżącego miesiąc ubiegłego roku';
							|tr = 'geçen yılın cari ayına benzer'");
	ElsIf Form.CalculationPeriod = PredefinedValue("Enum.Periodicity.Quarter") Then
		CurrentPeriod     = NStr("vi = 'quý hiện tại';
								|ru = 'текущий квартал';
								|en = 'current quarter'; fa = 'current quarter';
								|it = 'trimestre corrente';
								|pl = 'obecny kwartał';
								|tr = 'bu çeyrek'");
		SimilarPeriod = NStr("vi = 'tương tự như quý hiện tại của năm ngoái';
							|ru = 'аналогичный текущему квартал прошлого года';
							|en = 'quarter of the last year similar to the current quarter'; fa = 'quarter of the last year similar to the current quarter';
							|it = 'il trimestre dell''anno scorso analogo a quello corrente';
							|pl = 'podobny do bieżącego kwartał ubiegłego roku';
							|tr = 'geçen yılın şu anki çeyreğine benzer'");
	ElsIf Form.CalculationPeriod = PredefinedValue("Enum.Periodicity.HalfYear") Then
		CurrentPeriod     = NStr("vi = 'nửa năm hiện tại';
								|ru = 'текущее полугодие';
								|en = 'current half-year'; fa = 'current half-year';
								|it = 'semestre corrente';
								|pl = 'obecne półrocze';
								|tr = 'mevcut yarıyıl'");
		SimilarPeriod = NStr("vi = 'tương tự như nửa hiện tại của năm ngoái';
							|ru = 'аналогичное текущему полугодие прошлого года';
							|en = 'half-year of the last year similar to the current half-year'; fa = 'half-year of the last year similar to the current half-year';
							|it = 'il semestre dell''anno scorso analogo a quello corrente';
							|pl = 'podobny do obecnego półrocze ubiegłego roku';
							|tr = 'geçen yılın şu anki yarısına benzer'");
	ElsIf Form.CalculationPeriod = PredefinedValue("Enum.Periodicity.Year") Then
		CurrentPeriod     = NStr("vi = 'năm nay';
								|ru = 'текущий год';
								|en = 'current year'; fa = 'current year';
								|it = 'anno corrente';
								|pl = 'bieżący rok';
								|tr = 'bu yıl'");
		SimilarPeriod = NStr("vi = 'năm ngoái';
							|ru = 'прошлый год';
							|en = 'previous year'; fa = 'previous year';
							|it = 'anno scorso';
							|pl = 'poprzedni rok';
							|tr = 'geçen yıl'");
	Else
		CurrentPeriod     = NStr("vi = '<Kỳ không được chỉ định>';
								|ru = '<период не указан>';
								|en = '<period is not specified>'; fa = '<period is not specified>';
								|it = '<il periodo non è indicato>';
								|pl = '<okres nie jest wskazany>';
								|tr = '<süre belirtilmedi>'");
		SimilarPeriod = NStr("vi = '<Kỳ không được chỉ định>';
							|ru = '<период не указан>';
							|en = '<period is not specified>'; fa = '<period is not specified>';
							|it = '<il periodo non è indicato>';
							|pl = '<okres nie jest wskazany>';
							|tr = '<süre belirtilmedi>'");
	EndIf;
	
	PreviousPeriod_ = SupplyClientServer.SettingDetails(Form.CalculationPeriod, Form.NumberOfCalculationPeriods);
	
	Form.HintCalculationValidityPeriod = StrTemplate(NStr("vi = 'Kỳ tính toán: %1.';
															|ru = 'Период действия расчета: %1.';
															|en = 'Settlement validity period:%1.'; fa = 'Settlement validity period:%1.';
															|it = 'Periodo di validità del calcolo: %1.';
															|pl = 'Okres ważności kalkulacji: %1.';
															|tr = 'Hesaplama geçerlilik dönemi: %1'"), CurrentPeriod);
	
	CalculationOfAverageDaily = NStr("vi = 'Tiêu thụ trung bình hàng ngày được tính trên cơ sở dữ liệu trong kỳ: %1.';
									|ru = 'Среднедневное потребление расчитывается по данным за период: %1.';
									|en = 'Average daily consumption is calculated according to data for the period:%1.'; fa = 'Average daily consumption is calculated according to data for the period:%1.';
									|it = 'Il consumo medio giornaliero è calcolato in base ai dati per il periodo: %1.';
									|pl = 'Średnie dzienne zużycie jest obliczane na podstawie danych z okresu: %1.';
									|tr = 'Ortalama günlük tüketim, dönem verilerine göre hesaplanır: %1.'");
	
	If Form.SeasonalFluctuationsRegistrationOption = PredefinedValue("Enum.SeasonalFluctuationsAccounting.BySamePeriodOfLastYear") Then
		Correction = NStr("vi = 'Tiêu thụ trung bình hàng ngày được điều chỉnh theo các động lực tiêu thụ của loại sản phẩm tương ứng. Động lực tiêu thụ theo danh mục sản phẩm được lập theo dữ liệu cho %1 và trong cùng Kỳ so với năm ngoái.';
							|ru = 'Среднедневное потребление корректируется согласно динамике потребления соответствующей товарной категории. Динамика потребления по товарной категории формируется по данным за %1 и за аналогичный период относительно прошлого года.';
							|en = 'Average daily consumption is adjusted according to consumption trends of the relevant product category. Consumption trends of the product category are generated based on data for %1 and the similar period relative to the previous year.'; fa = 'Average daily consumption is adjusted according to consumption trends of the relevant product category. Consumption trends of the product category are generated based on data for %1 and the similar period relative to the previous year.';
							|it = 'Il consumo medio giornaliero viene rettificato in base alle dinamiche di consumo della categoria di prodotto appropriata. La dinamica di consumo per categoria di prodotto viene generata in base ai dati per %1 e per il periodo analogo rispetto all''anno precedente.';
							|pl = 'Średnie dzienne zużycie jest korygowane zgodnie z dynamiką zużycia odpowiedniej kategorii produktu. Dynamikę konsumpcji według kategorii produktów kształtuje się według danych za %1 i ten sam okres w porównaniu do roku poprzedniego.';
							|tr = 'Ortalama günlük tüketim, ilgili ürün kategorisinin tüketim dinamiklerine göre ayarlanmıştır. Ürün kategorisine göre tüketim dinamikleri %1 ve bir önceki yıla göre aynı dönem verilerine dayanmaktadır.'");
		
		Form.HintCalculationOfAverageDailyConsumption = New FormattedString(
			StrTemplate(CalculationOfAverageDaily, SimilarPeriod), Chars.LF, StrTemplate(Correction, PreviousPeriod_));
	ElsIf Form.SeasonalFluctuationsRegistrationOption = PredefinedValue("Enum.SeasonalFluctuationsAccounting.BySeasonalIndexes") Then
		LinkToForm = ?(Form.SeasonalIndexesAreAvailable, "e1cib/command/InformationRegister.SeasonalIndexes.Command.SeasonalIndexes", "");
		Correction = New FormattedString(
			NStr("vi = 'Lượng tiêu thụ trung bình hàng ngày được điều chỉnh theo';
				|ru = 'Среднедневное потребление корректируется согласно';
				|en = 'Average daily consumption is corrected according to'; fa = 'Average daily consumption is corrected according to';
				|it = 'Il consumo medio giornaliero viene rettificato in base a';
				|pl = 'Średnie dzienne spożycie dostosowuje się zgodnie z';
				|tr = 'Ortalama günlük tüketim'"),
			" ",
			New FormattedString(NStr("vi = 'tỷ lệ cược theo mùa';
									|ru = 'сезонным коэффициентам';
									|en = 'seasonal indexes'; fa = 'seasonal indexes';
									|it = 'coefficienti stagionali';
									|pl = 'współczynniki sezonowe';
									|tr = 'sezonluk oranlar'"),,,, LinkToForm),
			" ",
			NStr("vi = 'nhóm theo mùa thích hợp.';
				|ru = 'соответствующей сезонной группы.';
				|en = 'of the corresponding seasonal group.'; fa = 'of the corresponding seasonal group.';
				|it = 'gruppo stagionale appropriato.';
				|pl = 'odpowiednia grupa sezonowa.';
				|tr = 'ilgili mevsimsel grubun.'"));
		
		Form.HintCalculationOfAverageDailyConsumption = New FormattedString(
			StrTemplate(CalculationOfAverageDaily, PreviousPeriod_), Chars.LF, Correction);
	Else
		Form.HintCalculationOfAverageDailyConsumption = New FormattedString(
			StrTemplate(CalculationOfAverageDaily, PreviousPeriod_));
	EndIf;
	
EndProcedure

&AtServer
Procedure SetLockBasedOnSeasonalCoefficients()
	
	ThisIsYear = CalculationPeriod = Enums.Periodicity.Year;
	
	Items.BySeasonalIndexes.Enabled                     = Not ThisIsYear And GetFunctionalOption("UseSeasonalIndexes");
	Items.CommentOnTheImpossibilityOfSeasonalCoefficients.Visible = ThisIsYear;
	
	If ThisIsYear And SeasonalFluctuationsRegistrationOption = Enums.SeasonalFluctuationsAccounting.BySeasonalIndexes Then
		SeasonalFluctuationsRegistrationOption = Enums.SeasonalFluctuationsAccounting.DontConsider;
	EndIf;
	
	ThePreviousCalculationPeriodWasAYear = ThisIsYear;
	
EndProcedure

&AtServer
Procedure SaveParameters()
	
	// The constants are recorded in privileged mode.
	SetPrivilegedMode(True);
	
	Constants.PeriodOfGoodsLimitationCalculation.Set(CalculationPeriod);
	Constants.NumberOfCommercialRestrictionCalculationPeriods.Set(NumberOfCalculationPeriods);
	Constants.SeasonalFluctuationsRegistrationOption.Set(SeasonalFluctuationsRegistrationOption);
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion
