#Region Public

// Clear Bank details depending on the application condition
//
// Parameters:
//  Object - CatalogObject.DiscountMarkupTerms - the element of the dictionary.
//
Procedure ClearDetailsDependingOnApplicationCondition(Object) Export
	
	If Object.IsFolder Then
		Return;
	EndIf;
	
	LineAllDetails = "OptionOfCumulativeQuantityDiscountPeriodDetermination, AccumulationOption, 
	                      |CriteriaOfApplicationLimitationForSalesVolume, RestrictionCurrency, PaymentSchedule, PaymentMethod,
	                      |RestrictionConditionValue, ProductSegmentRestrictions, AccumulationPeriod,
	                      |ComparisonTypeSSL, UsersGroup, LoyaltyCardKind, 
	                      |PartnersSegment, NumberOfAccumulationPeriods, TimeOfValidity,
	                      |NumberOfDaysBeforeBirthday, NumberOfDaysAfterBirthday, IncludeCurrentSaleInAccumulatedSalesVolume,
	                      |ItemFilterOption";
	
	If Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.IncludeCustomerInSegment") Then
		
		StringUsedBankingDetails = "PartnersSegment";
		
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.DuringSale") Then
		
		StringUsedBankingDetails = "TimeOfValidity";
	
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForPaymentSchedule") Then
		
		StringUsedBankingDetails = "PaymentSchedule";
		
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForCustomerSBirthday") Then
		
		StringUsedBankingDetails = "NumberOfDaysBeforeBirthday,NumberOfDaysAfterBirthday";
		
	ElsIf TypeOf(Object.DiscountMarkupCondition) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		
		StringUsedBankingDetails = "";
		
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForAccumulatedSalesVolume") Then
		
		StringUsedBankingDetails = "OptionOfCumulativeQuantityDiscountPeriodDetermination, AccumulationOption, CriteriaOfApplicationLimitationForSalesVolume,
		                              |RestrictionCurrency,ComparisonTypeSSL,
		                              |RestrictionConditionValue, ProductSegmentRestrictions, AccumulationPeriod,
		                              |ComparisonTypeSSL, PartnersSegment, NumberOfAccumulationPeriods, IncludeCurrentSaleInAccumulatedSalesVolume";
		
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForLoyaltyCard") Then
		
		StringUsedBankingDetails = "LoyaltyCardKind";
		
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForOneTimeSalesVolume") Then
		
		StringUsedBankingDetails = "CriteriaOfApplicationLimitationForSalesVolume,
		                             |RestrictionCurrency,ComparisonTypeSSL,
		                             |RestrictionConditionValue, ProductSegmentRestrictions,
		                             |ComparisonTypeSSL, PartnersSegment";
		
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForPaymentForm") Then
		
		StringUsedBankingDetails = "PaymentMethod";
		
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.LoyaltyCardIsNotRegistered") Then
		
		StringUsedBankingDetails = "LoyaltyCardKind";
		
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.LimitationByUserGroup") Then
		
		StringUsedBankingDetails = "UsersGroup";
		
	EndIf;
	
	DetailsUsed = StringFunctionsClientServer.SplitStringIntoSubstringsArray(StringUsedBankingDetails, ",", True, True);
	AllAttributes = StringFunctionsClientServer.SplitStringIntoSubstringsArray(LineAllDetails, ",", True, True);
	
	For Each ArrayElement In DetailsUsed Do
	
		SequenceNumber = AllAttributes.Find(ArrayElement);
		If SequenceNumber <> Undefined Then
			AllAttributes.Delete(SequenceNumber);
		EndIf;
	
	EndDo;
	
	For Each PropsForCleaning In AllAttributes Do
	
		If PropsForCleaning = "OptionOfCumulativeQuantityDiscountPeriodDetermination" Then
			
			Object.OptionOfCumulativeQuantityDiscountPeriodDetermination = PredefinedValue("Enum.OptionsOfEstimatingCumulativeQuantityDiscountPeriod.EmptyRef");
			
		ElsIf PropsForCleaning = "AccumulationOption" Then
			
			Object.AccumulationOption = PredefinedValue("Enum.OptionsOfCumulativeDiscountMarkupAccumulation.EmptyRef");
			
		ElsIf PropsForCleaning = "CriteriaOfApplicationLimitationForSalesVolume" Then
			
			Object.CriteriaOfApplicationLimitationForSalesVolume = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.EmptyRef");
			
		ElsIf PropsForCleaning = "RestrictionCurrency" Then
			
			Object.RestrictionCurrency = PredefinedValue("Catalog.Currencies.EmptyRef");
			
		ElsIf PropsForCleaning = "PaymentSchedule" Then
			
			Object.PaymentSchedule = PredefinedValue("Catalog.PaymentSchedules.EmptyRef");
			
		ElsIf PropsForCleaning = "PaymentMethod" Then
			
			Object.PaymentMethod = PredefinedValue("Enum.PaymentForms.EmptyRef");
			
		ElsIf PropsForCleaning = "RestrictionConditionValue" Then
			
			Object.RestrictionConditionValue = 0;
			
		ElsIf PropsForCleaning = "ProductSegmentRestrictions" Then
			
			Object.ProductSegmentRestrictions = PredefinedValue("Catalog.ProductSegments.EmptyRef");
			
		ElsIf PropsForCleaning = "AccumulationPeriod" Then
			
			Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.EmptyRef");
			
		ElsIf PropsForCleaning = "ComparisonTypeSSL" Then
			
			Object.ComparisonTypeSSL = PredefinedValue("Enum.DiscountMarkupValueComparisonTypes.EmptyRef");
			
		ElsIf PropsForCleaning = "UsersGroup" Then
			
			Object.UsersGroup = PredefinedValue("Catalog.UserGroups.EmptyRef");
			
		ElsIf PropsForCleaning = "LoyaltyCardKind" Then
			
			Object.LoyaltyCardKind = PredefinedValue("Catalog.LoyaltyCardKinds.EmptyRef");
			
		ElsIf PropsForCleaning = "PartnersSegment" Then
			
			Object.PartnersSegment = PredefinedValue("Catalog.PartnersSegments.EmptyRef");
			
		ElsIf PropsForCleaning = "NumberOfAccumulationPeriods" Then
			
			Object.NumberOfAccumulationPeriods = 0;
			
		ElsIf PropsForCleaning = "TimeOfValidity" Then
			
			Object.TimeOfValidity.Clear();
			
		EndIf;
	
	EndDo;

EndProcedure

// Auto-naming discount conditions
//
// Parameters:
//  Form - ClientApplicationForm - The form to be modified must contain, among other things:
//  	* Items - FormItems:
//  		** Description - FormField
// 
// Returns:
//  String - Description
//
Function AutoNameDiscountConditions(Form) Export
	
	Form.Items["Description"].ChoiceList.Clear();
	
	Object = Form.Object;
	
	AccordingToWhatProductRange = "";
	If Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.ItemList") Then
		If String(Form.ProductItemList) <> NStr("vi = 'Thêm';
												|ru = 'Добавить';
												|en = 'Add'; fa = 'افزودن';
												|it = 'Aggiungere';
												|pl = 'Add';
												|tr = 'Ekle'") Then
			AccordingToWhatProductRange = StrTemplate(NStr("vi = 'theo mặt hàng từ danh sách: %1';
															|ru = 'по номенклатуре из списка: %1';
															|en = 'for products from the list: %1'; fa = 'for products from the list: %1';
															|it = 'in base agli articoli dall''elenco: %1';
															|pl = 'wg nomenklatury z listy: %1';
															|tr = 'listedeki öğeye göre: %1'"), Form.ProductItemList);
		EndIf
	ElsIf Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.ProductSegment") Then
		AccordingToWhatProductRange = StrTemplate(NStr("vi = 'theo mặt hàng từ phân khúc %1';
														|ru = 'по номенклатуре из сегмента %1';
														|en = 'for products from segment %1'; fa = 'for products from segment %1';
														|it = 'in base agli articoli dal segmento %1';
														|pl = 'wg nomenklatury z segmentu: %1';
														|tr = 'segmentteki öğeye göre %1'"), Object.ProductSegmentRestrictions);
	ElsIf Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.NotProductSegment") Then
		AccordingToWhatProductRange = StrTemplate(NStr("vi = 'theo mặt hàng không phải từ phân khúc %1';
														|ru = 'по номенклатуре не из сегмента %1';
														|en = 'for products not from segment %1'; fa = 'for products not from segment %1';
														|it = 'Per nomenclatura non facente parte del segmento %1';
														|pl = 'wg pozycji nie z segmentu %1';
														|tr = '%1 segmentinde olmayan öğeye göre'"), Object.ProductSegmentRestrictions);
	ElsIf Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter") Then
		AccordingToWhatProductRange = NStr("vi = 'theo mặt hàng đã chọn';
											|ru = 'по отобранной номенклатуре';
											|en = 'by selected items'; fa = 'by selected items';
											|it = 'in base agli articoli selezionati';
											|pl = 'zgodnie z wyselekcjonowaną nomenklaturą';
											|tr = 'Seçilen öğeye göre'");
	EndIf;
	
	If Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.DuringSale") Then
		NameString_ = NStr("vi = 'Thời gian bán hàng:';
							|ru = 'Время продажи:';
							|en = 'Time of sale:'; fa = 'Time of sale:';
							|it = 'Orario di vendita:';
							|pl = 'Czas sprzedaży:';
							|tr = 'Satış zamanı:'");
		FirstDay = True;
		For Each TableRow In Object.TimeOfValidity Do
			NameString_ = NameString_ + 
			                     ?(FirstDay," ", ", ")+ TableRow.WeekDay + 
			                     StrTemplate(NStr("vi = '(từ %1 đến %2)';
													|ru = '(с %1 до %2)';
													|en = '(from %1 till %2)'; fa = '(from %1 till %2)';
													|it = '(dalle %1 alle %2)';
													|pl = '(od %1 do %2)';
													|tr = '(%1 itibaren %2 kadar)'"), Format(TableRow.BeginTime,"DF=HH:mm"), Format(TableRow.EndTime,"DF=HH:mm"));
			FirstDay = False;
		EndDo;
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForPaymentForm") Then
		NameString_ = StrTemplate(NStr("vi = 'Hình thức thanh toán: %1';
										|ru = 'Форма оплаты: %1';
										|en = 'Payment method: %1'; fa = 'Payment method: %1';
										|it = 'Modalità di pagamento: %1';
										|pl = 'Forma płatności: %1';
										|tr = 'Ödeme formu: %1'"), Object.PaymentMethod);
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForCustomerSBirthday") Then
		NameString_ = NStr("vi = 'Sinh nhật của khách hàng';
							|ru = 'День рождения клиента';
							|en = 'Customer birthday'; fa = 'Customer birthday';
							|it = 'Data di nascita del cliente';
							|pl = 'Urodziny klienta';
							|tr = 'Müşteri doğum günü'");
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.IncludeCustomerInSegment") Then
		NameString_ = StrTemplate(NStr("vi = 'Khách hàng thuộc phân khúc: %1';
										|ru = 'Клиент входит в сегмент: %1';
										|en = 'Customer is included in the segment: %1'; fa = 'Customer is included in the segment: %1';
										|it = 'Il cliente rientra nel segmento: %1';
										|pl = 'Klient wchodzi do segmentu: %1';
										|tr = 'Müşteri segmente dahil: %1'"), Object.PartnersSegment);
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForPaymentSchedule") Then
		NameString_ = StrTemplate(NStr("vi = 'Lịch biểu thanh toán: %1';
										|ru = 'График оплаты: %1';
										|en = 'Payment schedule: %1'; fa = 'Payment schedule: %1';
										|it = 'Grafico di pagamento: %1';
										|pl = 'Harmonogram płatności: %1';
										|tr = 'Ödeme planı: %1'"), Object.PaymentSchedule);
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.LoyaltyCardIsNotRegistered") Then
		NameString_ = StrTemplate(NStr("vi = 'Chưa ghi nhận thẻ khách hàng thân thiết ""%1""';
										|ru = 'Карта лояльности ""%1"" не зарегистрирована';
										|en = 'Loyalty card ""%1"" is not registered'; fa = 'Loyalty card ""%1"" is not registered';
										|it = 'La carta fedeltà ""%1"" non è registrata';
										|pl = 'Karta lojalnościowa ""%1"" nie jest zarejestrowana';
										|tr = '""%1"" sadakat kartı kaydedilmedi'"), Object.LoyaltyCardKind);
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForLoyaltyCard") Then
		NameString_ = StrTemplate(NStr("vi = 'Khách hàng sở hữu thẻ khách hàng thân thiết ""%1""';
										|ru = 'Клиент владелец карты лояльности ""%1""';
										|en = 'Customer, the ""%1"" loyalty card holder'; fa = 'Customer, the ""%1"" loyalty card holder';
										|it = 'Cliente titolare della carta fedeltà ""%1""';
										|pl = 'Właściciel karty lojalności ""%1""';
										|tr = 'Müşteri sadakat kartı sahibi  ""%1""'"), Object.LoyaltyCardKind);
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.LimitationByUserGroup") Then
		NameString_ = StrTemplate(NStr("vi = 'Nhóm người sử dụng: %1';
										|ru = 'Группа пользователей: %1';
										|en = 'User group: %1'; fa = 'User group: %1';
										|it = 'Gruppo utenti: %1';
										|pl = 'Grupa użytkowników: %1';
										|tr = 'Kullanıcı grubu: %1'"), Object.UsersGroup);
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForOneTimeSalesVolume") Then
		
		If Object.CriteriaOfApplicationLimitationForSalesVolume = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Count") Then
			NameString_ = StrTemplate(
				NStr("vi = 'Số lượng trong chứng từ %1 %2 đơn vị. %3';
					|ru = 'Количество в документе %1 %2 ед. %3';
					|en = 'Quantity in the document %1 %2 units %3'; fa = 'Quantity in the document %1 %2 units %3';
					|it = 'Quantità nel documento %1 %2 unità %3';
					|pl = 'Ilość w dokumencie %1 %2 jedn. %3';
					|tr = 'Belgedeki miktar %1 %2 birim. %3'"),
				Object.ComparisonTypeSSL,
				Object.RestrictionConditionValue,
				AccordingToWhatProductRange);
		ElsIf Object.CriteriaOfApplicationLimitationForSalesVolume = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.DifferentItemsCount") Then
			NameString_ = StrTemplate(
				NStr("vi = 'Số lượng mặt hàng khác nhau trong chứng từ %1 %2 c. %3';
					|ru = 'Количество различных наименований в документе %1 %2 шт. %3';
					|en = 'Quantity of different names in document %1 %2 items %3'; fa = 'Quantity of different names in document %1 %2 items %3';
					|it = 'Numero di diversi nomi nel documento %1 %2 pz. %3';
					|pl = 'Ilość różnych pozycji w dokumencie %1 %2 szt. %3';
					|tr = 'Belgedeki farklı öğelerin sayısı %1 %2 adet. %3'"),
				Object.ComparisonTypeSSL,
				Object.RestrictionConditionValue,
				AccordingToWhatProductRange);
		ElsIf Object.CriteriaOfApplicationLimitationForSalesVolume = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.NumberOfSimilarOnes") Then
			NameString_ = StrTemplate(
				NStr("vi = 'Số lượng mặt hàng giống nhau trong chứng từ %1 %2 đv. %3';
					|ru = 'Количество одинаковых позиций в документе %1 %2 ед. %3';
					|en = 'Quantity of the same items in the %1 %2 document %3 units'; fa = 'Quantity of the same items in the %1 %2 document %3 units';
					|it = 'Numero di posizioni identiche nel documento %1 %2 pz. %3';
					|pl = 'Ilość identycznych pozycji w dokumencie %1 %2 jedn. %3';
					|tr = 'Belgedeki aynı öğelerin sayısı %1 %2 birim.%3 '"),
				Object.ComparisonTypeSSL,
				Object.RestrictionConditionValue,
				AccordingToWhatProductRange);
		ElsIf Object.CriteriaOfApplicationLimitationForSalesVolume = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Sum") Then
			NameString_ = StrTemplate(
				NStr("vi = 'Số tiền trong chứng từ %1 %2%3%4';
					|ru = 'Сумма в документе %1 %2 %3 %4';
					|en = 'Amount in document %1 %2 %3 %4'; fa = 'Amount in document %1 %2 %3 %4';
					|it = 'Importo nel documento %1 %2 %3 %4';
					|pl = 'Wartość w dokumencie %1 %2 %3 %4';
					|tr = 'Belgedeki miktar %1 %2 %3 %4'"),
				Object.ComparisonTypeSSL,
				Object.RestrictionConditionValue,
				Object.RestrictionCurrency,
				AccordingToWhatProductRange);
		EndIf;
		
	ElsIf Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForAccumulatedSalesVolume") Then
	
		If Object.OptionOfCumulativeQuantityDiscountPeriodDetermination = PredefinedValue("Enum.OptionsOfEstimatingCumulativeQuantityDiscountPeriod.WholePeriod") Then
			
			Period = NStr("vi = 'cho toàn bộ kỳ';
							|ru = 'за весь период';
							|en = 'for the whole period'; fa = 'برای کل دوره';
							|it = 'per tutto il periodo';
							|pl = 'za cały okres';
							|tr = 'tüm dönemlik'");
			
		ElsIf Object.OptionOfCumulativeQuantityDiscountPeriodDetermination = PredefinedValue("Enum.OptionsOfEstimatingCumulativeQuantityDiscountPeriod.PreviousPeriod") Then
			
			String = "";
			If Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Year") Then
				String = NStr("vi = 'năm trước,năm trước,năm trước';
								|ru = 'прошлый год,прошлых года,прошлых лет';
								|en = 'previous year, previous years'; fa = 'previous year, previous years';
								|it = 'anno precedente,anni precedenti,anni precedenti';
								|pl = 'ubiegły rok,ubiegłego roku,ubiegłych lat';
								|tr = 'geçen sene, geçen sene, geçen yılların'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.TenDays") Then
				String = NStr("vi = '10 ngày trước,10 ngày trước,10 ngày trước';
								|ru = 'прошлую декаду,прошлых декады,прошлых декад';
								|en = 'previous ten-day period, previous ten-day periods'; fa = 'previous ten-day period, previous ten-day periods';
								|it = 'decade precedente,decadi precedenti,decadi precedenti';
								|pl = 'ubiegłej dekady,ubiegłych dekad,ubiegłych dekad';
								|tr = 'geçen 10 günlük süre, geçen 10 günlük süreler, geçen 10 günlük süreler'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Day") Then
				String = NStr("vi = 'ngày trước,ngày trước,ngày trước';
								|ru = 'прошлый день,прошлых дня,прошлых дней';
								|en = 'previous day, previous days'; fa = 'previous day, previous days';
								|it = 'giorno precedente,giorni precedenti,giorni precedenti';
								|pl = 'ubiegły dzień,ubiegłego dnia,ubiegłych dni';
								|tr = 'geçen gün, geçen gün, geçen günler'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Quarter") Then
				String = NStr("vi = 'quý trước,quý trước,quý trước';
								|ru = 'прошлый квартал,прошлых квартала,прошлых кварталов';
								|en = 'previous quarter, previous quarters'; fa = 'previous quarter, previous quarters';
								|it = 'trimestre precedente,trimestri precedenti,trimestri precedenti';
								|pl = 'ubiegły kwartał,ubiegłego kwartału,ubiegłych kwartałów';
								|tr = 'geçen çeyrek, geçen çeyrek, geçen çeyrekler'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Month") Then
				String = NStr("vi = 'tháng trước,tháng trước,tháng trước';
								|ru = 'прошлый месяц,прошлых месяца,прошлых месяцев';
								|en = 'previous month, previous months'; fa = 'previous month, previous months';
								|it = 'mese precedente,mesi precedenti,mesi precedenti';
								|pl = 'ubiegły miesiąc,ubiegłego miesiąca,ubiegłych miesięcy';
								|tr = 'geçen ay, geçen ay, geçen ayların'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Week") Then
				String = NStr("vi = 'tuần trước,tuần trước,tuần trước';
								|ru = 'прошлую неделю,прошлых недели,прошлых недель';
								|en = 'previous week, previous weeks'; fa = 'previous week, previous weeks';
								|it = 'settimana precedente,settimane precedenti,settimane precedenti';
								|pl = 'ubiegły tydzień,ubiegłego tygodnia,ubiegłych tygodni';
								|tr = 'geçen hafta, geçen haftalar, geçen haftarların'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.HalfYear") Then
				String = NStr("vi = 'nửa năm trước,nửa năm trước,nửa năm trước';
								|ru = 'прошлое полугодие,прошлых полугодия,прошлых полугодий';
								|en = 'previous half-year, previous half-year periods'; fa = 'previous half-year, previous half-year periods';
								|it = 'semestre precedente,semestri precedenti,semestri precedenti';
								|pl = 'ubiegłe pół roku,ubiegłego pół roku,ubiegłych pół roku';
								|tr = 'geçen yarıyıl, geçen yarıyılın, geçen yarıyılların'");
			EndIf;
			
			Period = StrTemplate(NStr("vi = 'cho %1';
										|ru = 'за %1';
										|en = 'for %1'; fa = 'for %1';
										|it = 'in %1';
										|pl = 'za %1';
										|tr = '%1 için'"), StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(Object.NumberOfAccumulationPeriods, String));
			
		ElsIf Object.OptionOfCumulativeQuantityDiscountPeriodDetermination = PredefinedValue("Enum.OptionsOfEstimatingCumulativeQuantityDiscountPeriod.SinceBeginningOfCurrentPeriod") Then
			
			If Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Year") Then
				Period = NStr("vi = 'từ đầu năm nay';
								|ru = 'с начала текущего года';
								|en = 'since the beginning of the current year'; fa = 'since the beginning of the current year';
								|it = 'dall''inizio dell''anno corrente';
								|pl = 'od początku bieżącego roku';
								|tr = 'bu yılın başlarından'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.TenDays") Then
				Period = NStr("vi = 'từ đầu kỳ 10 ngày này';
								|ru = 'с начала текущей декады';
								|en = 'since the beginning of the current ten-day period'; fa = 'since the beginning of the current ten-day period';
								|it = 'dall''inizio della decade corrente';
								|pl = 'od początku bieżącej dekady';
								|tr = 'bu 10 günlük sürenin başlangıcından itibaren'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Day") Then
				Period = NStr("vi = 'từ đầu ngày hôm nay';
								|ru = 'с начала текущего дня';
								|en = 'since the beginning of the current day'; fa = 'since the beginning of the current day';
								|it = 'dall''inizio del giorno corrente';
								|pl = 'od początku bieżącego dnia';
								|tr = 'bu günün başlangıcından itibaren'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Quarter") Then
				Period = NStr("vi = 'từ đầu quý này';
								|ru = 'с начала текущего квартала';
								|en = 'since the beginning of the current quarter'; fa = 'since the beginning of the current quarter';
								|it = 'dall''inizio del trimestre corrente';
								|pl = 'od początku bieżącego kwartału';
								|tr = 'bu çeyreğin başlangıcından itibaren'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Month") Then
				Period = NStr("vi = 'từ đầu tháng này';
								|ru = 'с начала текущего месяца';
								|en = 'since the beginning of the current month'; fa = 'since the beginning of the current month';
								|it = 'dall''inizio del mese corrente';
								|pl = 'od początku bieżącego miesiąca';
								|tr = 'bu ayın başlangıcından itibaren'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Week") Then
				Period = NStr("vi = 'từ đầu tuần này';
								|ru = 'с начала текущей недели';
								|en = 'since the beginning of the current week'; fa = 'since the beginning of the current week';
								|it = 'dall''inizio della settimana corrente';
								|pl = 'od początku bieżącego tygodnia';
								|tr = 'bu haftanın başlangıcından itibaren'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.HalfYear") Then
				Period = NStr("vi = 'từ đầu nửa năm nay';
								|ru = 'с начала текущего полугодия';
								|en = 'since the beginning of the current half-year'; fa = 'since the beginning of the current half-year';
								|it = 'dall''inizio del semestre corrente';
								|pl = 'od początku bieżącego półrocza';
								|tr = 'bu yarıyılın başlangıcından itibaren'");
			EndIf;
			
		ElsIf Object.OptionOfCumulativeQuantityDiscountPeriodDetermination = PredefinedValue("Enum.OptionsOfEstimatingCumulativeQuantityDiscountPeriod.PreviousRollingPeriod") Then
			
			String = "";
			If Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Year") Then
				String = NStr("vi = 'năm trước, năm trước, năm trước';
								|ru = 'предыдущий год,предыдущих года,предыдущих лет';
								|en = 'previous year, previous years, previous years'; fa = 'previous year, previous years, previous years';
								|it = 'anno precedente,anni precedenti,anni precedenti';
								|pl = 'ubiegły rok,ubiegłego roku,ubiegłych lat';
								|tr = 'önceki sene, önceki sene, önceki yılların'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.HalfYear") Then
				String = NStr("vi = 'nửa năm trước, nửa năm trước, nửa năm trước';
								|ru = 'предыдущее полугодие,предыдущих полугодия,предыдущих полугодий';
								|en = 'previous half-year, previous halves of the year, previous halves of the year'; fa = 'previous half-year, previous halves of the year, previous halves of the year';
								|it = 'semestre precedente,semestri precedenti,semestri precedenti';
								|pl = 'ubiegłe pół roku,ubiegłego pół roku,ubiegłych pół roku';
								|tr = 'önceki yarıyıl, önceki yarıyıl, önceki yarıyılların'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Quarter") Then
				String = NStr("vi = 'quý trước, quý trước, quý trước';
								|ru = 'предыдущий квартал,предыдущих квартала,предыдущих кварталов';
								|en = 'previous quarter, previous quarters, previous quarters'; fa = 'previous quarter, previous quarters, previous quarters';
								|it = 'trimestre precedente,trimestri precedenti,trimestri precedenti';
								|pl = 'ubiegły kwartał,ubiegłego kwartału,ubiegłych kwartałów';
								|tr = 'önceki çeyrek, önceki çeyrek, önceki çeyreklerin'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Month") Then
				String = NStr("vi = 'tháng trước,tháng trước,tháng trước';
								|ru = 'предыдущий месяц,предыдущих месяца,предыдущих месяцев';
								|en = 'previous month, previous months, previous months'; fa = 'previous month, previous months, previous months';
								|it = 'mese precedente,mesi precedenti,mesi precedenti';
								|pl = 'ubiegły miesiąc,ubiegłego miesiąca,ubiegłych miesięcy';
								|tr = 'önceki ay, önceki ay, önceki ayların'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.TenDays") Then
				String = NStr("vi = '10 ngày trước,10 ngày trước,10 ngày trước';
								|ru = 'предыдущую декаду,предыдущих декады,предыдущих декад';
								|en = 'previous ten-day period, previous ten-day periods, previous ten-day periods'; fa = 'previous ten-day period, previous ten-day periods, previous ten-day periods';
								|it = 'decade precedente,decadi precedenti,decadi precedenti';
								|pl = 'ubiegłej dekady,ubiegłych dekad,ubiegłych dekad';
								|tr = 'önceki 10 günlük süre, önceki 10 günlük süre, önceki 10 günlük sürelerin'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Week") Then
				String = NStr("vi = 'tuần trước, tuần trước, tuần trước';
								|ru = 'предыдущую неделю,предыдущих недель,предыдущих недель';
								|en = 'previous week, previous weeks, previous weeks'; fa = 'previous week, previous weeks, previous weeks';
								|it = 'settimana precedente,settimane precedenti,settimane precedenti';
								|pl = 'ubiegły tydzień,ubiegłego tygodnia,ubiegłych tygodni';
								|tr = 'önceki hafta, önceki hafta, önceki haftaların'");
			ElsIf Object.AccumulationPeriod = PredefinedValue("Enum.Periodicity.Day") Then
				String = NStr("vi = 'ngày trước,ngày trước,ngày trước';
								|ru = 'предыдущий день,предыдущих дня,предыдущих дней';
								|en = 'previous day, previous days, previous days'; fa = 'previous day, previous days, previous days';
								|it = 'giorno precedente,giorni precedenti,giorni precedenti';
								|pl = 'ubiegły dzień,ubiegłego dnia,ubiegłych dni';
								|tr = 'önceki gün, önceki gün, önceki günlerin'");
			EndIf;
			
			Period = StrTemplate(NStr("vi = 'cho %1';
										|ru = 'за %1';
										|en = 'for %1'; fa = 'for %1';
										|it = 'in %1';
										|pl = 'za %1';
										|tr = '%1 için'"), StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(Object.NumberOfAccumulationPeriods, String));
			
		EndIf;
		
		AccumulationOption = ?(Object.AccumulationOption = PredefinedValue("Enum.OptionsOfCumulativeDiscountMarkupAccumulation.ByPartner"), NStr("vi = 'theo khách hàng';
																																				|ru = 'по клиенту';
																																				|en = 'by customer'; fa = 'by customer';
																																				|it = 'per cliente';
																																				|pl = 'przez klienta';
																																				|tr = 'müşteriye göre'"), NStr("vi = 'theo thỏa thuận thương mại';
																																											|ru = 'по торговому соглашению';
																																											|en = 'by terms of sales'; fa = 'by terms of sales';
																																											|it = 'secondo l''accordo commerciale';
																																											|pl = 'wg umowy handlowej';
																																											|tr = 'ticari anlaşmaya göre'"));
		
		If Object.CriteriaOfApplicationLimitationForSalesVolume = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Count") Then
			NameString_ = StrTemplate(
				NStr("vi = 'Số lượng mặt hàng đã bán %4 %1 %2 đv.  %3';
					|ru = 'Количество проданной номенклатуры %4 %1 %2 ед. %3';
					|en = 'Number of sold products %4 %1 %2 units %3'; fa = 'Number of sold products %4 %1 %2 units %3';
					|it = 'Numero di articoli venduti %4 %1 %2 unità %3';
					|pl = 'Liczba sprzedanej nomenklatury %4 %1 %2 jedn. %3';
					|tr = 'Satılan öğe miktarı %4 %1 %2 birim. %3'"),
				Object.ComparisonTypeSSL,
				Object.RestrictionConditionValue,
				AccordingToWhatProductRange,
				AccumulationOption);
		ElsIf Object.CriteriaOfApplicationLimitationForSalesVolume = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.DifferentItemsCount") Then
			NameString_ = StrTemplate(
				NStr("vi = 'Số lượng tên gọi khác nhau của mặt hàng đã bán %4  %1  %2 c. %3';
					|ru = 'Количество различных наименований проданной номенклатуры %4 %1 %2 шт. %3';
					|en = 'Quantity of different names of sold products %4 %1 %2 items %3'; fa = 'Quantity of different names of sold products %4 %1 %2 items %3';
					|it = 'Numero di diversi nomi degli articoli venduti %4 %1 %2 pz. %3';
					|pl = 'Ilość różnych tytułów sprzedanej nomenklatury %4 %1 %2 szt. %3';
					|tr = 'Satılan farklı öğe tanımlarının sayısı %4 %1 %2 adet %3'"),
				Object.ComparisonTypeSSL,
				Object.RestrictionConditionValue,
				AccordingToWhatProductRange,
				AccumulationOption);
		ElsIf Object.CriteriaOfApplicationLimitationForSalesVolume = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.NumberOfSimilarOnes") Then
			NameString_ = StrTemplate(
				NStr("vi = 'Số lượng mục mặt hàng giống hệt nhau của mặt hàng đã bán %4 %1 %2 đv. %3';
					|ru = 'Количество одинаковых позиций проданной номенклатуры %4 %1 %2 ед. %3';
					|en = 'Quantity of duplicate items of sold products %4 %1 %2 units %3'; fa = 'Quantity of duplicate items of sold products %4 %1 %2 units %3';
					|it = 'Numero di posizioni identiche degli articoli venduti %4 %1 %2 pz. %3';
					|pl = 'Ilość jednakowych tytułów sprzedanej nomenklatury %4 %1 %2 szt. %3';
					|tr = 'Satılan öğelerin aynı konumlarının sayısı %4 %1 %2 birim. %3'"),
				Object.ComparisonTypeSSL,
				Object.RestrictionConditionValue,
				AccordingToWhatProductRange,
				AccumulationOption);
		ElsIf Object.CriteriaOfApplicationLimitationForSalesVolume = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Sum") Then
			NameString_ = StrTemplate(
				NStr("vi = 'Số tiền mặt hàng đã bán %5 %1 %2%3%4';
					|ru = 'Сумма проданной номенклатуры %5 %1 %2 %3 %4';
					|en = 'Amount of sold products %5 %1 %2 %3 %4'; fa = 'Amount of sold products %5 %1 %2 %3 %4';
					|it = 'Importo degli articoli venduti %5 %1 %2 %3 %4';
					|pl = 'Wartość sprzedanej nomenklatury %5 %1 %2 %3 %4';
					|tr = 'Satılan öğe tutarı %5 %1 %2 %3 %4'"),
				Object.ComparisonTypeSSL,
				Object.RestrictionConditionValue,
				Object.RestrictionCurrency,
				AccordingToWhatProductRange, 
				AccumulationOption);
		EndIf;
		
	ElsIf TypeOf(Object.DiscountMarkupCondition) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		
		NameString_ = Form.AutomaticNamingOfExternalDataProcessor;
		
	EndIf;

	FormFieldName = Form.Items.Description; // FormField
	
	FormFieldName.ChoiceList.Add(NameString_);
	
	If Form.AutomaticNamingIndex <= FormFieldName.ChoiceList.Count() - 1 Then
		Return FormFieldName.ChoiceList.Get(Form.AutomaticNamingIndex).Value;
	Else
		Return NameString_;
	EndIf;

EndFunction

// Update auto-naming details
//
// Parameters:
//  Form - ClientApplicationForm - The form to be modified must contain, among other things:
//  	* Items - FormItems:
//  		** Description - FormField
//
Procedure UpdateAutoNamingDetails(Form) Export
	
	Form.AutomaticNamingIndex = 0;
	Form.NameIsChangedByUser = True;
	Form.AutoNameIsUsed = False;
	FormFieldName = Form.Items.Description;
	FormFieldNameSelectionList = FormFieldName.ChoiceList; // ValueList
	For Each ListItem In FormFieldNameSelectionList Do
		
		If ListItem.Value = FormFieldName Then
			Form.AutoNameIsUsed = True;
			Form.NameIsChangedByUser = False;
			Form.AutomaticNamingIndex = FormFieldNameSelectionList.IndexOf(ListItem);
		EndIf;
		
	EndDo;
	
EndProcedure

// Sets up the hyperlink text for item selection.
//
// Parameters:
//	Form - ClientApplicationForm - Change shape
Procedure ConfigureSelectionHyperlinks(Form) Export
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "SettingsComposerFilterByProducts") Then
		ConfigureHyperlinkSelection(Form, "SettingsComposerFilterByProducts");
	EndIf;
	
#If Client Then
	ColorOfHyperlink = CommonClientCached.StyleColor("HyperlinkColor");
#Else
	ColorOfHyperlink = StyleColors.HyperlinkColor;
#EndIf
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "SettingsComposerAdditionalConditions") Then
		ConfigureHyperlinkSelection(
			Form,
			"SettingsComposerAdditionalConditions",
			ColorOfHyperlink,
			NStr("vi = 'Không làm rõ';
				|ru = 'Без уточнений';
				|en = 'Without details'; fa = 'Without details';
				|it = 'Senza chiarimenti';
				|pl = 'Bez objaśnień';
				|tr = 'İyileştirme olmadan'"),
			NStr("vi = 'Bằng cách đó';
				|ru = 'По которой';
				|en = 'By which'; fa = 'By which';
				|it = 'Secondo il quale';
				|pl = 'W której';
				|tr = 'Hangi'"));
	EndIf;
	
EndProcedure

// Configures the text of hyperlinks to the list of item items.
//
// Parameters:
//	Form - ClientApplicationForm - Changeable form, contains, among other things:
//		* Object - DocumentObject - Document
Procedure ConfigureHyperlinkToListOfItems(Form) Export
	
	TotalItems = 0;
	NumberOfFirstPositions = 0;
	
	If ValueIsFilled(Form.Object.Ref) Then
		DataForPresentationOfListOfProducts = DiscountsMarkupsServerCall.DataForPresentationOfListOfProducts(Form.Object.Ref);
		NumberOfFirstPositions = DataForPresentationOfListOfProducts.FirstPositions.Count();
		TotalItems = DataForPresentationOfListOfProducts.TotalItems;
	EndIf;
	
	PresentationOfListOfProducts = "";
	If NumberOfFirstPositions > 0 Then
		PresentationOfListOfProducts = StrConcat(DataForPresentationOfListOfProducts.FirstPositions, ", ");
	Else
		PresentationOfListOfProducts = NStr("vi = 'Thêm';
											|ru = 'Добавить';
											|en = 'Add'; fa = 'افزودن';
											|it = 'Aggiungere';
											|pl = 'Dodaj';
											|tr = 'Ekle'");
	EndIf;
	If NumberOfFirstPositions < TotalItems Then
		PresentationOfListOfProducts = PresentationOfListOfProducts
		                           + " " + NStr("vi = 'và hơn thế nữa';
												|ru = 'и еще';
												|en = 'and'; fa = 'و';
												|it = 'e anche';
												|pl = 'i jeszcze';
												|tr = 've daha'") + " "
		                           + StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(TotalItems - NumberOfFirstPositions, NStr("vi = 'vị trí, vị trí, vị trí';
																																					|ru = 'позиция,позиции,позиций';
																																					|en = 'position,positions,positions'; fa = 'position,positions,positions';
																																					|it = 'posizione, posizioni, posizioni';
																																					|pl = 'pozycja,pozycji,pozycji';
																																					|tr = 'konum,konumlar,konumların'"));
	EndIf;
	
#If Client Then
	ColorOfHyperlink = CommonClientCached.StyleColor("HyperlinkColor");
#Else
	ColorOfHyperlink = StyleColors.HyperlinkColor;
#EndIf
	
	Form.ProductItemList = New FormattedString(
		PresentationOfListOfProducts,
		New Font(,, False,,,False),
		ColorOfHyperlink,,"Change");
	
EndProcedure

// Event handler for changing the option field for determining the cumulative discount period.
//
// Parameters:
//	Form - ClientApplicationForm - Change shape
//
Procedure OptionForDeterminingCumulativeDiscountPeriodWhenChangingOnServer(Form) Export
	
	If Form.Object.OptionOfCumulativeQuantityDiscountPeriodDetermination = PredefinedValue("Enum.OptionsOfEstimatingCumulativeQuantityDiscountPeriod.WholePeriod") Then
		Form.Items.AccumulationPeriod.Visible = False;
		Form.Items.DecorationEqual.Visible = False;
		Form.Items.NumberOfAccumulationPeriods.Visible = False;
	ElsIf Form.Object.OptionOfCumulativeQuantityDiscountPeriodDetermination = PredefinedValue("Enum.OptionsOfEstimatingCumulativeQuantityDiscountPeriod.SinceBeginningOfCurrentPeriod") Then
		Form.Items.AccumulationPeriod.Visible = True;
		Form.Items.DecorationEqual.Visible = True;
		Form.Items.NumberOfAccumulationPeriods.Visible = False;
		Form.Object.NumberOfAccumulationPeriods = 1;
	Else
		Form.Items.AccumulationPeriod.Visible = True;
		Form.Items.DecorationEqual.Visible = True;
		Form.Items.NumberOfAccumulationPeriods.Visible = True;
	EndIf;
	
EndProcedure

// Event handler for changes in the application Criteria for sales volume field
//
// Parameters:
//	Form - ClientApplicationForm - Change shape
//
Procedure CriteriaForApplyingForSalesVolumeWhenChangingOnServer(Form) Export
	
	DifferentItemsCount = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.DifferentItemsCount");
	NumberOfSimilarOnes = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.NumberOfSimilarOnes");
	Count = PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Count");
	
	Form.Items.ApplyVariants.Visible = (Form.Object.CriteriaOfApplicationLimitationForSalesVolume = DifferentItemsCount
		Or Form.Object.CriteriaOfApplicationLimitationForSalesVolume = NumberOfSimilarOnes);
	Form.Items.TakeIntoAccountTheCharacteristicsForTheAccumulatedSalesVolume.Visible = (Form.Object.CriteriaOfApplicationLimitationForSalesVolume = DifferentItemsCount
		Or Form.Object.CriteriaOfApplicationLimitationForSalesVolume = NumberOfSimilarOnes);
	
	If Form.Object.CriteriaOfApplicationLimitationForSalesVolume = Count
	Or Form.Object.CriteriaOfApplicationLimitationForSalesVolume = NumberOfSimilarOnes
	Or Form.Object.CriteriaOfApplicationLimitationForSalesVolume = DifferentItemsCount Then
		
		Form.Items.RestrictionCurrency.Visible = False;
		Form.Items.CurrencyOfTheLimitForTheAccumulatedSalesVolume.Visible = False;
		Form.Items.CurrencyRestrictionsDoNotUseMultipleCurrenciesForAccumulatedSalesVolume.Visible = False;
		Form.Items.RestrictionCurrencyDoNotUseSeveralCurrencies.Visible = False;
		
	Else
		
		Form.Items.RestrictionCurrency.Visible = True;
		Form.Items.CurrencyOfTheLimitForTheAccumulatedSalesVolume.Visible = True;
		Form.Items.CurrencyRestrictionsDoNotUseMultipleCurrenciesForAccumulatedSalesVolume.Visible = True;
		Form.Items.RestrictionCurrencyDoNotUseSeveralCurrencies.Visible = True;
		
	EndIf;
	
	Form.Items.DecorationOfPositionsInTheDocument.Visible = (Form.Object.CriteriaOfApplicationLimitationForSalesVolume = DifferentItemsCount
		Or Form.Object.CriteriaOfApplicationLimitationForSalesVolume = NumberOfSimilarOnes);
	Form.Items.DecorationInTheDocument.Visible = Not (Form.Object.CriteriaOfApplicationLimitationForSalesVolume = DifferentItemsCount
		Or Form.Object.CriteriaOfApplicationLimitationForSalesVolume = NumberOfSimilarOnes);
	
	Form.Items.DecorationOfThePositionsOfTheSoldGoods.Visible = (Form.Object.CriteriaOfApplicationLimitationForSalesVolume = DifferentItemsCount
		Or Form.Object.CriteriaOfApplicationLimitationForSalesVolume = NumberOfSimilarOnes);
	Form.Items.DecorationOfTheSoldProduct.Visible = Not (Form.Object.CriteriaOfApplicationLimitationForSalesVolume = DifferentItemsCount
		Or Form.Object.CriteriaOfApplicationLimitationForSalesVolume = NumberOfSimilarOnes);
	
	SetFormatOfTermsOfServiceValue(
		Form.Object.CriteriaOfApplicationLimitationForSalesVolume,
		Form.Items.MeaningOfTheTermsOfService);
	
	SetFormatOfTermsOfServiceValue(
		Form.Object.CriteriaOfApplicationLimitationForSalesVolume,
		Form.Items.TheValueOfTheProvisionConditionForTheAccumulatedSalesVolume);

EndProcedure

// Event handler for a change in the grant Condition field
//
// Parameters:
//	Form - ClientApplicationForm - Change shape
//
Procedure ProvisionConditionWhenChangedOnServer(Form) Export
	
	Form.Items.ForOneTimeSalesVolume.Visible              = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForOneTimeSalesVolume"));
	Form.Items.ForAccumulatedSalesVolume.Visible          = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForAccumulatedSalesVolume"));
	Form.Items.ForPaymentSchedule.Visible                    = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForPaymentSchedule"));
	Form.Items.ForATrialSale.Visible                  = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForATrialSale"));
	Form.Items.ForTheDurationOfTheAction.Visible                   = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.DuringSale"));
	Form.Items.ForFirstSaleToCustomer.Visible           = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForFirstSaleToCustomer"));
	Form.Items.ForPaymentForm.Visible                     = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForPaymentForm"));
	Form.Items.LimitationByUserGroup.Visible  = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.LimitationByUserGroup"));
	Form.Items.LoyaltyCardIsNotRegistered.Visible = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.LoyaltyCardIsNotRegistered"));
	Form.Items.ForLoyaltyCard.Visible          = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForLoyaltyCard"));
	Form.Items.IncludeCustomerInSegment.Visible         = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.IncludeCustomerInSegment"));
	Form.Items.ForThePartnerSBirthday.Visible            = (Form.Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForCustomerSBirthday"));
	Form.Items.ExternalDataProcessor.Visible                  = (TypeOf(Form.Object.DiscountMarkupCondition) = Type("CatalogRef.AdditionalReportsAndDataProcessors"));
	
	If TypeOf(Form.Object.DiscountMarkupCondition) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		
		DescriptionOfExternalProcessing = DiscountsMarkupsServerCall.DescriptionOfExternalProcessing(
				Form.Object.DiscountMarkupCondition,
				Form.AddressOfExternalDataProcessorSettings);
		
		Form.DescriptionOfTheExternalProcessingAction = DescriptionOfExternalProcessing.ActionDetails;
		Form.AutomaticNamingOfExternalDataProcessor = DescriptionOfExternalProcessing.AutoDescription;
		Form.NameOfExternalDataProcessorSettingForm = DescriptionOfExternalProcessing.SettingsFormName;
		Form.Items.ShowTheExternalProcessingSettingsForm.Visible = ValueIsFilled(Form.NameOfExternalDataProcessorSettingForm);
	
	EndIf;
	
EndProcedure

// Rounds up the value of the restriction condition.
//
// Parameters:
// 	RestrictionCriteria - EnumRef.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume
// 	RestrictionConditionValue - Number
//
Procedure RoundUpValueOfRestrictionCondition(RestrictionCriteria, RestrictionConditionValue) Export
	
	RestrictionConditionValue = Round(RestrictionConditionValue,
		ComplianceWithCriteriaOfRestrictionsAndNumberOfDigits().Get(RestrictionCriteria));
	
EndProcedure

#EndRegion

#Region Private

// View of the selection field
//
// Parameters:
//  Field - DataCompositionField - Field
//  Denial - Boolean - Indicates the presence of negation
//  Lower - Boolean - Indicates whether lowercase is used.
// 
// Returns:
//  String - Representation of the selection field.
//
Function PresentationOfSelectionField(Field, Denial = False, Lower = False)
	
	If String(Field) = "PriceKind" Then
		ReturnValue = NStr("vi = 'Dạng giá';
							|ru = 'Вид цены';
							|en = 'Price type'; fa = 'نوع قیمت';
							|it = 'Tipo di prezzo';
							|pl = 'Rodzaj ceny';
							|tr = 'Fiyat türü'");
	ElsIf String(Field) = "ProductSegment" Then
		ReturnValue = NStr("vi = 'Mặt hàng trong phân khúc';
							|ru = 'Номенклатура входит в сегмент';
							|en = 'Items are included in segment'; fa = 'اقلام در بخش گنجانده شده‌اند';
							|it = 'Gli articoli entrano nel segmento';
							|pl = 'Nomenklatura zawarta w segmencie';
							|tr = 'Öğe segmente dahil'");
	ElsIf String(Field) = "NotProductSegment" Then
		ReturnValue = NStr("vi = 'Mặt hàng không trong phân khúc';
							|ru = 'Номенклатура не входит в сегмент';
							|en = 'Items are not included in segment'; fa = 'اقلام در بخش گنجانده نشده‌اند';
							|it = 'La nomenclatura non è inclusa nel segmento';
							|pl = 'Pozycje nie są zawarte w segmencie';
							|tr = 'Öğe, segmente dahil değil'");
	ElsIf String(Field) = "CustomerPurchasesGoodsForTheFirstTime" Then
		
		If Denial Then
			ReturnValue = NStr("vi = 'Đây không phải là lần đầu tiên khách hàng mua sản phẩm';
								|ru = 'Клиент покупает товар не в первый раз';
								|en = 'Customer purchases the goods not for the first time'; fa = 'Customer purchases the goods not for the first time';
								|it = 'Non è la prima volta che Il cliente acquista la merce';
								|pl = 'Klient kupuje towar nie pierwszy raz';
								|tr = 'Müşteri ürünü ilk defa satın almıyor'");
		Else
			ReturnValue = NStr("vi = 'Khách hàng mua hàng lần đầu tiên';
								|ru = 'Клиент покупает товар в первый раз';
								|en = 'Customer purchases goods for the first time'; fa = 'مشتری برای اولین بار کالا خریداری می‌کند';
								|it = 'Il cliente acquista la merce per prima volta';
								|pl = 'Klient dokonuje zakupu po raz pierwszy';
								|tr = 'Müşteri ürünü ilk kez satın alıyor'");
		EndIf;
		
	ElsIf String(Field) = "QuantityWithoutCharacteristics" Then
		
		ReturnValue = NStr("vi = 'Số lượng giống nhau';
							|ru = 'Количество одинаковых';
							|en = 'Number of similar ones'; fa = 'تعداد موارد مشابه';
							|it = 'Numero di uguali';
							|pl = 'Ilość jednakowych';
							|tr = 'Aynı olanların miktarı'");
		
	ElsIf String(Field) = "AmountWithoutCharacteristics" Then
		
		ReturnValue = NStr("vi = 'Số tiền giống nhau';
							|ru = 'Сумма по одинаковым';
							|en = 'Amount by the same ones'; fa = 'مبلغ بر اساس موارد یکسان';
							|it = 'Somma per uguali';
							|pl = 'Suma jednakowych';
							|tr = 'Aynı olanların tutarı'");
		
	ElsIf String(Field) = "Count" Then
		
		ReturnValue = NStr("vi = 'Số lượng giống nhau (có tính đến các đặc tính)';
							|ru = 'Количество одинаковых (с учетом характеристик)';
							|en = 'Number of similar (considering variants)'; fa = 'تعداد مشابه (با احتساب گونه‌ها)';
							|it = 'Il numero degli uguali (tenendo conto delle caratteristiche)';
							|pl = 'Ilość jednakowych (z uwzględnieniem cech charakterystycznych)';
							|tr = 'Aynı olanların miktarı (varyantları dikkate alarak)'");
		
	ElsIf String(Field) = "Sum" Then
		
		ReturnValue = NStr("vi = 'Số tiền giống nhau (có tính đến các đặc tính)';
							|ru = 'Сумма по одинаковым (с учетом характеристик)';
							|en = 'Amount by the same ones (considering variants)'; fa = 'مبلغ بر اساس موارد یکسان (با احتساب گونه‌ها)';
							|it = 'Somma per uguali (considerando le caratteristiche)';
							|pl = 'Suma jednakowych (z uwzględnieniem cech charakterystycznych)';
							|tr = 'Aynı olanların tutarı (varyantları dikkate alarak)'");
		
	ElsIf String(Field) = "ArbitraryPriceIsSet" Then
		
		If Denial Then
			ReturnValue = NStr("vi = 'Chưa đặt giá tùy ý';
								|ru = 'Не задана произвольная цена';
								|en = 'Arbitrary price is not specified'; fa = 'Arbitrary price is not specified';
								|it = 'Nessun prezzo arbitrario specificato';
								|pl = 'Nie podano dowolnej ceny';
								|tr = 'Keyfi fiyat belirlenmedi'");
		Else
			ReturnValue = NStr("vi = 'Đã đặt giá tùy ý';
								|ru = 'Задана произвольная цена';
								|en = 'Arbitrary price is set'; fa = 'قیمت دلخواه تعیین شده است';
								|it = 'Prezzo libero specificato';
								|pl = 'Zadana cena losowa';
								|tr = 'Serbest fiyat belirtildi'");
		EndIf;
		
	ElsIf String(Field) = "GoodsAvailabilityForCustomer" Then
		
		ReturnValue = NStr("vi = 'Sản phẩm có sẵn cho khách hàng';
							|ru = 'Доступность товара для клиента';
							|en = 'Goods availability for customer'; fa = 'در دسترس بودن کالا برای مشتری';
							|it = 'Disponibilità della merce per il cliente';
							|pl = 'Dostępność towaru dla klienta';
							|tr = 'Müşteri için ürün mevcutluğu'");
		
	ElsIf String(Field) = "PriceIsSameAsPriceOfAgreement" Then
		
		If Denial Then
			ReturnValue = NStr("vi = 'Giá không khớp với giá niêm yết từ thỏa thuận';
								|ru = 'Цена не совпадает с уточненной ценой из соглашения';
								|en = 'The price does not match the one specified in the agreement'; fa = 'The price does not match the one specified in the agreement';
								|it = 'Il prezzo non coincide con il prezzo corretto secondo l''accordo';
								|pl = 'Cena nie pokrywa się z uwzględnioną przez umowę ceną';
								|tr = 'Fiyat, anlaşmadaki iyileştirilmiş fiyatla eşleşmiyor'");
		Else
			ReturnValue = NStr("vi = 'Giá là giá quy định từ thỏa thuận';
								|ru = 'Цена совпадает с уточненной ценой из соглашения';
								|en = 'Price matches the specified price from the agreement'; fa = 'قیمت با قیمت مشخص‌شده در توافق‌نامه مطابقت دارد';
								|it = 'Il prezzo è lo stesso del prezzo corretto dall''accordo.';
								|pl = 'Cena zgodna z uzgodnioną ceną na umowie';
								|tr = 'Fiyat, anlaşmada belirtilen fiyatla eşleşmektedir'");
		EndIf;
		
	Else
		ReturnValue = String(Field);
	EndIf;
	
	If Lower Then
		ReturnValue = Lower(ReturnValue);
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Procedure-Configure the selection hyperlink
//
// Parameters:
//  Form - ClientApplicationForm - Change shape
//  Name - String - Name of the selection settings element
//  ColorSelectionIsNotSet - Color - The selection color is not set
//  TextSelectionNotSet - String - Text selection is not set
//  Prefix - String - prefix.
//
Procedure ConfigureHyperlinkSelection(Form, Name, Val ColorSelectionIsNotSet = Undefined, Val TextSelectionNotSet = Undefined, Val Prefix = "")
	
	Lower = ValueIsFilled(Prefix);
	
#If Client Then
	ColorOfHyperlink = CommonClientCached.StyleColor("HyperlinkColor");
#Else
	ColorOfHyperlink = StyleColors.HyperlinkColor;
#EndIf

#If Client Then
	ErrorNoteText = CommonClientCached.StyleColor("ErrorNoteText");
#Else
	ErrorNoteText = StyleColors.ErrorNoteText;
#EndIf
	
	DataCompositionSettings = Form[Name].Settings; // DataCompositionSettings
	FilterPresentation = FilterPresentation(DataCompositionSettings.Filter.Items, Lower);
	
	If ColorSelectionIsNotSet = Undefined Then
		If Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter") Then
			ColorSelectionIsNotSet = ErrorNoteText;
		Else
			ColorSelectionIsNotSet = ColorOfHyperlink;
		EndIf;
	EndIf;
	If TextSelectionNotSet = Undefined Then
		TextSelectionNotSet = NStr("vi = 'Chưa thiết lập phễu lọc';
									|ru = 'Отбор не установлен';
									|en = 'Filter not set'; fa = 'Filter not set';
									|it = 'La selezione non è impostata';
									|pl = 'Filtr nie jest ustawiony';
									|tr = 'Filtre kurulmadı'");
	EndIf;
	
	If ValueIsFilled(FilterPresentation) And Prefix <> "" Then
		FilterPresentation = Prefix + " " + FilterPresentation;
	EndIf;
	
	If Name = "SettingsComposerFilterByProducts" Then
		NameOfPresentation = "SettingsComposerFilterByProductsPresentation";
	ElsIf Name = "SettingsComposerAdditionalConditions" Then 
		NameOfPresentation = "SettingsComposerAdditionalConditionsPresentation";
	Else
		NameOfPresentation = "";
	EndIf;
	
	If Not IsBlankString(NameOfPresentation) Then
		If ValueIsFilled(FilterPresentation) Then
			Form[NameOfPresentation] = New FormattedString(
				FilterPresentation,
				New Font(,, False,,,False),
				ColorOfHyperlink,,Name);
		Else
			Form[NameOfPresentation] = New FormattedString(
				TextSelectionNotSet,
				New Font(,, False,,,False),
				ColorSelectionIsNotSet,,Name);
		EndIf;
	EndIf;
	
EndProcedure

// Selection view
//
// Parameters:
//  FilterItems1 - DataCompositionFilterItemCollection - Selection element
//  Lower - Boolean - Indicates whether lowercase is used
//  ElementSeparator - String - Separator.
// 
// Returns:
//  String - the view selection.
//
Function FilterPresentation(FilterItems1, Lower, ElementSeparator = ", ")
	
	FilterPresentation = "";
	
	For Each FilterElement In FilterItems1 Do
		
		If FilterPresentation = "" Then
			Separator = "";
		Else
			Separator = ElementSeparator;
		EndIf;
		
		If FilterElement.Use Then
			If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
				If (FilterElement.ComparisonType = DataCompositionComparisonType.Equal Or FilterElement.ComparisonType = DataCompositionComparisonType.NotEqual)
					And TypeOf(FilterElement.RightValue) = Type("Boolean") Then
					
					If FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
						
						If FilterElement.RightValue = True Then
							FIlterRow = StrTemplate(
								NStr("vi = '%1';
									|ru = '%1';
									|en = '%1'; fa = '%1';
									|it = '%1';
									|pl = '%1';
									|tr = '%1'"), PresentationOfSelectionField(FilterElement.LeftValue, False, Lower));
						Else
							FIlterRow = StrTemplate(
								NStr("vi = '%1';
									|ru = '%1';
									|en = '%1'; fa = '%1';
									|it = '%1';
									|pl = '%1';
									|tr = '%1'"), PresentationOfSelectionField(FilterElement.LeftValue, True, Lower));
						EndIf;
						
					Else
						
						If FilterElement.RightValue = True Then
							FIlterRow = StrTemplate(
								NStr("vi = '%1';
									|ru = '%1';
									|en = '%1'; fa = '%1';
									|it = '%1';
									|pl = '%1';
									|tr = '%1'"), PresentationOfSelectionField(FilterElement.LeftValue, True, Lower));
						Else
							FIlterRow = StrTemplate(
								NStr("vi = '%1';
									|ru = '%1';
									|en = '%1'; fa = '%1';
									|it = '%1';
									|pl = '%1';
									|tr = '%1'"), PresentationOfSelectionField(FilterElement.LeftValue, False, Lower));
						EndIf;
						
					EndIf;
					
				Else
					
					FIlterRow = StrTemplate(
						NStr("vi = '%1 %2 ""%3""';
							|ru = '%1 %2 ""%3""';
							|en = '%1 %2 ""%3""'; fa = '%1 %2 ""%3""';
							|it = '%1 %2 ""%3""';
							|pl = '%1 %2 ""%3""';
							|tr = '%1 %2 ""%3""'"),
						PresentationOfSelectionField(FilterElement.LeftValue, False, Lower), Lower(FilterElement.ComparisonType), FilterElement.RightValue);
					
				EndIf;
			Else
				
				If FilterElement.GroupType = DataCompositionFilterItemsGroupType.AndGroup Then
					FIlterRow = "(" + FilterPresentation(FilterElement.Items, Lower) + ")";
				ElsIf FilterElement.GroupType = DataCompositionFilterItemsGroupType.OrGroup Then
					FIlterRow = "(" + FilterPresentation(FilterElement.Items, Lower," " + NStr("vi = 'Hoặc';
																								|ru = 'Или';
																								|en = 'Or'; fa = 'یا';
																								|it = 'Oppure';
																								|pl = 'Lub';
																								|tr = 'Veya'")) + " )";
				ElsIf FilterElement.GroupType = DataCompositionFilterItemsGroupType.NotGroup Then
					FIlterRow = NStr("vi = 'Không';
									|ru = 'Не';
									|en = 'Not'; fa = 'Not';
									|it = 'Non';
									|pl = 'Nie';
									|tr = 'NOT'") + " (" + FilterPresentation(FilterElement.Items, Lower) + ")";
				EndIf;
				
			EndIf;
			FilterPresentation = FilterPresentation
			                    + Separator
			                    + FIlterRow;
			
		EndIf;
		
	EndDo;
	
	Return FilterPresentation;
	
EndFunction

// Returns the compliance of the number of digits with the criteria for restrictions on the use of discounts.
//
// Returns:
// 	Map of EnumRef.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume
//
Function ComplianceWithCriteriaOfRestrictionsAndNumberOfDigits()
	
	Result = New Map();
	Result.Insert(PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Sum"), 2);
	Result.Insert(PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Count"), 3);
	Result.Insert(PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.NumberOfSimilarOnes"), 0);
	Result.Insert(PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.DifferentItemsCount"), 0);
	Result.Insert(PredefinedValue("Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.EmptyRef"), 0);
	
	Return Result;
	
EndFunction

// Sets the format for editing the value of the discount submission condition.
//
// Parameters:
// 	RestrictionCriteria - EnumRef.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume
// 	ValueOfElementRestrictionCondition - FormField
//
Procedure SetFormatOfTermsOfServiceValue(RestrictionCriteria,
	ValueOfElementRestrictionCondition)
	
	DigitsCount = ComplianceWithCriteriaOfRestrictionsAndNumberOfDigits().Get(RestrictionCriteria);
	ValueOfElementRestrictionCondition.EditFormat = StrTemplate(
		NStr("ru = 'ЧДЦ=%1;';
			|vi = 'NFD=%1;';
			|en = 'NFD=%1;'; fa = 'NFD=%1;';
			|it = 'NFD=%1;';
			|pl = 'NFD=%1;';
			|tr = 'NFD=%1;'"),
		Format(DigitsCount, NStr("ru = 'ЧДЦ=0; ЧН=;';
								|vi = 'NFD=0; NZ=;';
								|en = 'NFD=0; NZ=;'; fa = 'NFD=0; NZ=;';
								|it = 'NFD=0; NZ=;';
								|pl = 'NFD=0; NZ=;';
								|tr = 'NFD=0; NZ=;'")));
	
EndProcedure

#EndRegion