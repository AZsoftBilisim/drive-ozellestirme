#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure")  Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	If ValueIsFilled(Source) And Source = Receiver Then
		Common.MessageToUser(NStr("vi = 'Nguồn và đích theo quy tắc tính không cần trùng nhau.';
									|ru = 'Источник и приемник по правилу расчета не должны совпадать.';
									|en = 'A source and a destination must be different according to the calculation rule.'; fa = 'A source and a destination must be different according to the calculation rule.';
									|it = 'A source and a destination must be different according to the calculation rule.';
									|pl = 'A source and a destination must be different according to the calculation rule.';
									|tr = 'Hesaplama kuralına göre kaynak ve alıcının çakışmaması gerekir.'"),
			, , , Cancel);
	ElsIf Not ValueIsFilled(Receiver) Or Not ValueIsFilled(SourceType) Then
		Return;
	ElsIf Not ValueIsFilled(Source) Then
		If SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
			Return;
		Else
			NotCheckedAttributeArray.Add("Source");
			If Enums.DataSourceTypesForBudgeting.OnlyQuantitativeAccountingBySourceType(SourceType) Then
				NotCheckedAttributeArray.Add("DataCalculationSettings.AmountSource");
			EndIf;
		EndIf;
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	NumberOfSettingsLines = DataCalculationSettings.Count();
	If NumberOfSettingsLines = 1 Then
		ErrorTextMissingCoefficient = NStr("vi = 'Chưa chỉ ra hệ số tính lại.';
											|ru = 'Не указан коэффициент пересчета.';
											|en = 'Conversion ratio is not specified.'; fa = 'Conversion ratio is not specified.';
											|it = 'Conversion ratio is not specified.';
											|pl = 'Conversion ratio is not specified.';
											|tr = 'Dönüştürme oranı belirtilmedi.'");
		TextOfNFPErrorDoesNotMatchSourceType = NStr("vi = 'Dạng đối tượng phân tích của chỉ tiêu phi tài chính %2 không tương ứng với kiểu nguồn %3';
													|ru = 'Виды аналитик нефинансового показателя %2 не соответствуют типу источника %3';
													|en = 'Dimension kinds  of the non-financial %2 item mismatch the %3 source type'; fa = 'Dimension kinds  of the non-financial %2 item mismatch the %3 source type';
													|it = 'Dimension kinds  of the non-financial %2 item mismatch the %3 source type';
													|pl = 'Dimension kinds  of the non-financial %2 item mismatch the %3 source type';
													|tr = 'Finansal olmayan %2 öğesinin boyut türleri, %3 kaynak türüne karşılık gelmiyor'");
		ErrorTextIncorrectNFPCoefficient = NStr("vi = 'Dạng đối tượng phân tích của chỉ tiêu phi tài chính %2 không tương ứng với dạng đối tượng phân tích %3';
												|ru = 'Виды аналитик нефинансового показателя %2 не соответствуют видам аналитик %3';
												|en = 'Dimension kinds  of the non-financial %2 item mismatch the %3 dimension kinds'; fa = 'Dimension kinds  of the non-financial %2 item mismatch the %3 dimension kinds';
												|it = 'Dimension kinds  of the non-financial %2 item mismatch the %3 dimension kinds';
												|pl = 'Dimension kinds  of the non-financial %2 item mismatch the %3 dimension kinds';
												|tr = 'Finansal olmayan %2 göstergesinin boyut türleri, %3 boyut türlerine karşılık gelmiyor'");
		ErrorTextRequiresMonetaryCoefficientOfNFP = NStr("vi = 'Đối với nguồn số tiền %2, cần chỉ định chỉ tiêu phi tài chính bằng tiền làm hệ số tính lại';
														|ru = 'Для источника суммы %2 в качестве коэффициента перерасчета должен быть указан денежный нефинансовый показатель';
														|en = 'For the %2 amount source, a monetary non-financial item must be specified as a recalculation factor'; fa = 'For the %2 amount source, a monetary non-financial item must be specified as a recalculation factor';
														|it = 'For the %2 amount source, a monetary non-financial item must be specified as a recalculation factor';
														|pl = 'For the %2 amount source, a monetary non-financial item must be specified as a recalculation factor';
														|tr = '%2 tutarının kaynağı için yeniden hesaplama katsayısı olarak finansal olmayan öğenin belirtilmesi gerekmektedir'");
		ErrorTextRequiresNonMonetaryNFPCoefficient = NStr("vi = 'Đối với nguồn số tiền %2, không thể chỉ định chỉ tiêu phi tài chính bằng tiền làm hệ số tính lại';
															|ru = 'Для источника суммы %2 в качестве коэффициента перерасчета нельзя указывать денежный нефинансовый показатель';
															|en = 'For the %2 amount source, cannot specify a monetary non-financial item as a recalculation factor'; fa = 'For the %2 amount source, cannot specify a monetary non-financial item as a recalculation factor';
															|it = 'For the %2 amount source, cannot specify a monetary non-financial item as a recalculation factor';
															|pl = 'For the %2 amount source, cannot specify a monetary non-financial item as a recalculation factor';
															|tr = '%2 tutarının kaynağı için yeniden hesaplama katsayısı olarak finansal olmayan öğe belirtilemez'");
		ErrorTextIsMissingTimeFence = NStr("vi = 'Chưa chỉ ra kỳ hỗn hợp.';
											|ru = 'Не указан период смещения.';
											|en = 'Offset period is not specified.'; fa = 'Offset period is not specified.';
											|it = 'Offset period is not specified.';
											|pl = 'Offset period is not specified.';
											|tr = 'Kayma dönemi belirtilmedi.'");
		ErrorTextMissingNumberOfPeriods = NStr("vi = 'Chưa chỉ ra số lượng kỳ hỗn hợp.';
												|ru = 'Не указано количество периодов смещения.';
												|en = 'Number of offset periods is not specified.'; fa = 'Number of offset periods is not specified.';
												|it = 'Number of offset periods is not specified.';
												|pl = 'Number of offset periods is not specified.';
												|tr = 'Kayma dönemlerinin sayısı belirtilmedi.'");
	Else
		ErrorTextMissingCoefficient = NStr("vi = 'Trong dòng số %1 chưa chỉ ra hệ số tính lại.';
											|ru = 'В строке № %1 не указан коэффициент пересчета.';
											|en = 'Conversion ratio is not specified in line #%1.'; fa = 'Conversion ratio is not specified in line #%1.';
											|it = 'Conversion ratio is not specified in line #%1.';
											|pl = 'Conversion ratio is not specified in line #%1.';
											|tr = '%1 numarası satırda dönüştürme oranı belirtilmedi.'");
		TextOfNFPErrorDoesNotMatchSourceType = NStr("vi = 'Trong dòng số %1 dạng đối tượng phân tích của chỉ tiêu phi tài chính %2 không tương ứng với kiểu nguồn %3';
													|ru = 'В строке № %1 виды аналитик нефинансового показателя %2 не соответствуют типу источника %3';
													|en = 'In line %1, dimension kinds  of the non-financial %2 item mismatch the %3 source type'; fa = 'In line %1, dimension kinds  of the non-financial %2 item mismatch the %3 source type';
													|it = 'In line %1, dimension kinds  of the non-financial %2 item mismatch the %3 source type';
													|pl = 'In line %1, dimension kinds  of the non-financial %2 item mismatch the %3 source type';
													|tr = '%1 numaralı satırda, finansal olmayan %2 öğesinin boyut türleri, %3 kaynak türüne karşılık gelmiyor'");
		ErrorTextIncorrectNFPCoefficient = NStr("vi = 'Trong dòng số %1 dạng đối tượng phân tích %2 không tương ứng dạng đối tượng phân tích %3';
												|ru = 'В строке № %1 виды аналитик %2 не соответствуют видам аналитик %3';
												|en = 'The %2 dimension kinds mismatch the %3 dimension kinds in line #%1'; fa = 'The %2 dimension kinds mismatch the %3 dimension kinds in line #%1';
												|it = 'The %2 dimension kinds mismatch the %3 dimension kinds in line #%1';
												|pl = 'The %2 dimension kinds mismatch the %3 dimension kinds in line #%1';
												|tr = '%1 numaralı satırda, %2 boyut türleri, %3 boyut türlerine karşılık gelmiyor'");
		ErrorTextRequiresMonetaryCoefficientOfNFP = NStr("vi = 'Trong dòng số %1, đối với nguồn số tiền %2 cần chỉ định chỉ tiêu phi tài chính bằng tiền làm hệ số tính lại';
														|ru = 'В строке № %1 для источника суммы %2 в качестве коэффициента перерасчета должен быть указан денежный нефинансовый показатель';
														|en = 'In line %1, for the %2 amount source, a monetary non-financial item must be specified as a recalculation factor'; fa = 'In line %1, for the %2 amount source, a monetary non-financial item must be specified as a recalculation factor';
														|it = 'In line %1, for the %2 amount source, a monetary non-financial item must be specified as a recalculation factor';
														|pl = 'In line %1, for the %2 amount source, a monetary non-financial item must be specified as a recalculation factor';
														|tr = '%2 tutarının kaynağı için %1 numaralı satırda yeniden hesaplama katsayısı olarak finansal olmayan öğenin belirtilmesi gerekmektedir'");
		ErrorTextRequiresNonMonetaryNFPCoefficient = NStr("vi = 'Trong dòng số %1, đối với nguồn số tiền %2 không thể chỉ định chỉ tiêu phi tài chính bằng tiền làm hệ số tính lại';
															|ru = 'В строке № %1 для источника суммы %2 в качестве коэффициента перерасчета нельзя указывать денежный нефинансовый показатель';
															|en = 'In line %1, for the %2 amount source, cannot specify a monetary non-financial item as a recalculation factor'; fa = 'In line %1, for the %2 amount source, cannot specify a monetary non-financial item as a recalculation factor';
															|it = 'In line %1, for the %2 amount source, cannot specify a monetary non-financial item as a recalculation factor';
															|pl = 'In line %1, for the %2 amount source, cannot specify a monetary non-financial item as a recalculation factor';
															|tr = '%2 tutarının kaynağı için %1 numaralı satırda finansal olmayan öğenin yeniden hesaplama katsayısı olarak belirtilemez'");
		ErrorTextIsMissingTimeFence = NStr("vi = 'Trong dòng số %1 chưa chỉ ra kỳ hỗn hợp.';
											|ru = 'В строке № %1 не указан период смещения.';
											|en = 'Offset period is not specified in line #%1.'; fa = 'Offset period is not specified in line #%1.';
											|it = 'Offset period is not specified in line #%1.';
											|pl = 'Offset period is not specified in line #%1.';
											|tr = '%1 numaralı satırda kayma dönemi belirtilmedi.'");
		ErrorTextMissingNumberOfPeriods = NStr("vi = 'Trong dòng số %1 chưa chỉ ra số lượng kỳ hỗn hợp.';
												|ru = 'В строке № %1 не указано количество периодов смещения.';
												|en = 'Number of offset periods is not specified in line #%1.'; fa = 'Number of offset periods is not specified in line #%1.';
												|it = 'Number of offset periods is not specified in line #%1.';
												|pl = 'Number of offset periods is not specified in line #%1.';
												|tr = '%1 numaralı satırda kayma dönemlerinin sayısı belirtilmedi.'");
	EndIf;
	For Each SettingString In DataCalculationSettings Do
		If Not ValueIsFilled(SettingString.ZoomRatio) And Not ValueIsFilled(SettingString.NFIFactor) Then
			Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTextMissingCoefficient, SettingString.LineNumber), , , , Cancel);
		ElsIf ValueIsFilled(SettingString.NFIFactor) Then
			If SourceType <> Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
				If BudgetingCached.ComplianceOfArticleAnalystWithNFPSIndicatorWithTypeOfPlanningSource(SourceType,
					SettingString.NFIFactor) = Undefined Then
					Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
						TextOfNFPErrorDoesNotMatchSourceType, SettingString.LineNumber, SettingString.NFIFactor,
						SourceType), , , , Cancel);
				EndIf;
			ElsIf BudgetingCached.ComplianceOfAnalystWithItemIndicatorOfSNFPBudgets(Source,
				SettingString.NFIFactor) = Undefined Then
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextIncorrectNFPCoefficient, SettingString.LineNumber, SettingString.NFIFactor,
					Source), , , , Cancel);
			EndIf;
			TypeOfNFPCoefficient = Common.ObjectAttributeValue(SettingString.NFIFactor, "IndicatorKind");
			If SettingString.AmountSource = Enums.IndicatorsOfAnalyticalRegisters.Count
				And TypeOfNFPCoefficient <> Enums.NonFinancialItemKinds.Cash_ Then
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextRequiresMonetaryCoefficientOfNFP, SettingString.LineNumber, SettingString.AmountSource), , , , Cancel);
			ElsIf ValueIsFilled(SettingString.AmountSource)
				And SettingString.AmountSource <> Enums.IndicatorsOfAnalyticalRegisters.Count
				And TypeOfNFPCoefficient = Enums.NonFinancialItemKinds.Cash_ Then
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextRequiresNonMonetaryNFPCoefficient, SettingString.LineNumber, SettingString.AmountSource), , , , Cancel);
			EndIf;
		Else
			If SettingString.AmountSource = Enums.IndicatorsOfAnalyticalRegisters.Count Then
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextRequiresMonetaryCoefficientOfNFP, SettingString.LineNumber, SettingString.AmountSource), , , , Cancel);
			EndIf;
		EndIf;
		If ValueIsFilled(SettingString.PeriodOffsetSettingOption)
			And SettingString.PeriodOffsetSettingOption <> Enums.PeriodOffsetSettingOptions.OnSchedule
			And Not ValueIsFilled(SettingString.OffsetFrequency) Then
			Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTextIsMissingTimeFence, SettingString.LineNumber), , , , Cancel);
		EndIf;
		If SettingString.PeriodOffsetSettingOption = Enums.PeriodOffsetSettingOptions.Manually
			And Not ValueIsFilled(SettingString.PeriodOfShift) Or SettingString.PeriodOffsetSettingOption
			= Enums.PeriodOffsetSettingOptions.FromDimension And Not ValueIsFilled(
			SettingString.ExpressionOffsetPeriod) Then
			Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTextMissingNumberOfPeriods, SettingString.LineNumber), , , , Cancel);
		EndIf;
	EndDo;
	
	DistributionProfiles = CommonClientServer.CollapseArray(
		DimensionFillingSettings.UnloadColumn("AllocationProfile"));
	CommonClientServer.SupplementArray(DistributionProfiles, DataCalculationSettings.UnloadColumn(
		"AllocationProfile"));
	CommonClientServer.DeleteAllValueOccurrencesFromArray(DistributionProfiles,
		Catalogs.NonFinancialItemsOfBudgets.EmptyRef());
	
	TypesOfProfileAnalytics = Undefined;
	If DistributionProfiles.Count() > 0 Then
		ArrayOfAnalyticsTypes = New Array;
		For Counter = 1 To BudgetingClientServer.MaximumNumberOfAnalysts() Do
			ArrayOfAnalyticsTypes.Add(StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1",
				Counter));
		EndDo;
		TypesOfProfileAnalytics = Common.ObjectsAttributesValues(DistributionProfiles, StrConcat(
			ArrayOfAnalyticsTypes, ","));
	EndIf;
	
	ErrorTextMissingExpression = NStr("vi = 'Đối với dạng đối tượng phân tích %1 chưa chọn biểu thức điền.';
										|ru = 'Для вида аналитики %1 не указано выражение заполнения.';
										|en = 'Filling expression is not specified for the %1 dimension kind.'; fa = 'Filling expression is not specified for the %1 dimension kind.';
										|it = 'Filling expression is not specified for the %1 dimension kind.';
										|pl = 'Filling expression is not specified for the %1 dimension kind.';
										|tr = '%1 boyut türü için doldurma ifadesi belirtilmedi.'");
	ErrorTextMissingProfile = NStr("vi = 'Đối với dạng đối tượng phân tích %1 chưa chỉ ra hồ sơ phân bổ.';
									|ru = 'Для вида аналитики %1 не указан профиль распределения.';
									|en = 'Allocation profile is not specified for the %1 dimension kind.'; fa = 'Allocation profile is not specified for the %1 dimension kind.';
									|it = 'Allocation profile is not specified for the %1 dimension kind.';
									|pl = 'Allocation profile is not specified for the %1 dimension kind.';
									|tr = '%1 boyut türü için dağıtım profili belirtilmedi.'");
	ErrorTextIncorrectProfile = NStr("vi = 'Đối với dạng đối tượng phân tích %1 đã chỉ ra sai hồ sơ phân bổ.';
									|ru = 'Для вида аналитики %1 указан некорректный профиль распределения.';
									|en = 'Incorrect allocation profile is specified for the %1 dimension kind.'; fa = 'Incorrect allocation profile is specified for the %1 dimension kind.';
									|it = 'Incorrect allocation profile is specified for the %1 dimension kind.';
									|pl = 'Incorrect allocation profile is specified for the %1 dimension kind.';
									|tr = '%1 boyut türü için hatalı dağıtım profili belirtildi.'");
	ErrorTextIterationNumberIsNotSpecified = NStr("vi = 'Đối với dạng đối tượng phân tích %1 chưa chỉ ra số thứ tự của hồ sơ phân bổ.';
													|ru = 'Для вида аналитики %1 не указан порядковый номер профиля распределения.';
													|en = 'Incorrect allocation profile number is specified for the %1 dimension kind.'; fa = 'Incorrect allocation profile number is specified for the %1 dimension kind.';
													|it = 'Incorrect allocation profile number is specified for the %1 dimension kind.';
													|pl = 'Incorrect allocation profile number is specified for the %1 dimension kind.';
													|tr = '%1 boyut türü için dağıtım profilinin sıra numarası belirtilmedi.'");
	ErrorTextMissingTypeOfAnalytics = NStr(
		"vi = 'Để tương ứng giá trị của dạng đối tượng phân tích %1 chưa chỉ ra dạng đối tượng phân tích của nguồn.';
		|ru = 'Для соответствия значений вида аналитики %1 не указан вид аналитики источника.';
		|en = 'Source dimension kind is not specified for matching the %1 dimension kind values.'; fa = 'Source dimension kind is not specified for matching the %1 dimension kind values.';
		|it = 'Source dimension kind is not specified for matching the %1 dimension kind values.';
		|pl = 'Source dimension kind is not specified for matching the %1 dimension kind values.';
		|tr = '%1 boyut türünün değerleriyle eşleşmesi için kaynak boyut türü belirtilmedi.'");
	ErrorTextIsMissingMatch = NStr(
		"vi = 'Đối với dạng đối tượng phân tích %1 chưa xác định sự tương ứng với giá trị của dạng đối tượng phân tích %2.';
		|ru = 'Для вида аналитики %1 не задано соответствие со значениями вида аналитики %2.';
		|en = 'The %2 dimension kind value match is not specified for the %1 dimension kind.'; fa = 'The %2 dimension kind value match is not specified for the %1 dimension kind.';
		|it = 'The %2 dimension kind value match is not specified for the %1 dimension kind.';
		|pl = 'The %2 dimension kind value match is not specified for the %1 dimension kind.';
		|tr = '%1 boyut türünün %2 boyut türünün değerleriyle eşleşmesi belirlenmedi.'");
	For Each SettingString In DimensionFillingSettings Do
		If SettingString.FillingMethod = Enums.MethodsOfFillingBudgetFlowItemDimensions.FromDataSource Then
			If Not ValueIsFilled(SettingString.DimensionPopulationExpression) Then
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextMissingExpression, SettingString.DimensionKind), , , , Cancel);
			EndIf;
		ElsIf SettingString.FillingMethod
			= Enums.MethodsOfFillingBudgetFlowItemDimensions.ByAllocationProfile Then
			If Not ValueIsFilled(SettingString.AllocationProfile) Then
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextMissingProfile, SettingString.DimensionKind), , , , Cancel);
			Else
				ProfileCorrespondsToTypeOfAnalytics = False;
				TypesOfProfileAnalysts = TypesOfProfileAnalytics.Get(SettingString.AllocationProfile);
				For Each KeyAndValue In TypesOfProfileAnalysts Do
					If KeyAndValue.Value = SettingString.DimensionKind Then
						ProfileCorrespondsToTypeOfAnalytics = True;
						Break;
					EndIf;
				EndDo;
				If Not ProfileCorrespondsToTypeOfAnalytics Then
					Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
						ErrorTextIncorrectProfile, SettingString.DimensionKind), , , , Cancel);
				EndIf;
			EndIf;
			If Not ValueIsFilled(SettingString.IterationNumber) Then
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextIterationNumberIsNotSpecified, SettingString.DimensionKind));
			EndIf;
		ElsIf SettingString.FillingMethod
			= Enums.MethodsOfFillingBudgetFlowItemDimensions.BySetValue Then
			If Not ValueIsFilled(SettingString.KindOfSourceDimension) Then
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextMissingTypeOfAnalytics, SettingString.DimensionKind), , , , Cancel);
			Else
				MapRow = MatchingAnalystValues.Find(SettingString.DimensionKind, "DimensionKind");
				If MapRow = Undefined Then
					Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
						ErrorTextIsMissingMatch, SettingString.DimensionKind,
						SettingString.KindOfSourceDimension), , , , Cancel);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	If Not Cancel Then
	
		ErrorTextIncorrectProfile = NStr(
			"vi = 'Hồ sơ phân bổ %1 được tính theo dạng đối tượng phân tích (%2), không có trong %3';
			|ru = 'Профиль распределения %1 учитывается по видам аналитик (%2), отсутствующих у %3';
			|en = 'The %1 allocation profile is accounted for by dimension kinds (%2) missing in %3'; fa = 'The %1 allocation profile is accounted for by dimension kinds (%2) missing in %3';
			|it = 'The %1 allocation profile is accounted for by dimension kinds (%2) missing in %3';
			|pl = 'The %1 allocation profile is accounted for by dimension kinds (%2) missing in %3';
			|tr = '%1 dağıtım profili, %3 dahilinde bulunmayan boyut türleri (%2) tarafından hesaba katılır'");
		If Not ValueIsFilled(Source) Then
			TypesOfSourceAnalytics = New Array;
		Else
			TypesOfSourceAnalytics = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
				BudgetingServer.DimensionKinds(Source), False);
		EndIf;
		TypesOfReceiverAnalytics = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
			BudgetingServer.DimensionKinds(Receiver), False);
		For Each AllocationProfile In DistributionProfiles Do
			IncorrectTypesOfAnalytics = New Array;
			ThisIsSourceProfile = DataCalculationSettings.Find(AllocationProfile, "AllocationProfile") <> Undefined;
			If ThisIsSourceProfile Then
				If SourceType <> Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
					If BudgetingCached.ComplianceOfArticleAnalystWithNFPSIndicatorWithTypeOfPlanningSource(SourceType,
						AllocationProfile) = Undefined Then
						Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
							TextOfNFPErrorDoesNotMatchSourceType, SettingString.LineNumber, AllocationProfile,
							SourceType), , , , Cancel);
					EndIf;
					Continue;
				EndIf;
				ComparedTypesOfAnalytics = TypesOfSourceAnalytics;
			Else
				ComparedTypesOfAnalytics = TypesOfReceiverAnalytics;
			EndIf;
			For Each KeyAndValue In TypesOfProfileAnalytics.Get(AllocationProfile) Do
				If ValueIsFilled(KeyAndValue.Value)
					And ComparedTypesOfAnalytics.Find(KeyAndValue.Value) = Undefined Then
					IncorrectTypesOfAnalytics.Add(KeyAndValue.Value);
				EndIf;
			EndDo;
			If IncorrectTypesOfAnalytics.Count() > 0 Then
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextIncorrectProfile, AllocationProfile, StrConcat(IncorrectTypesOfAnalytics, ", "),
					?(ThisIsSourceProfile, Source, Receiver)), , , , Cancel);
			EndIf;
		EndDo;
	
	EndIf;
	
	If Not Cancel Then
		
		ErrorTextInvalidIterationNumber = NStr("vi = 'Đối với dạng đối tượng phân tích %1 đã chỉ ra sai số thứ tự của hồ sơ phân bổ (cần đứng trước hồ sơ %2).';
												|ru = 'Для вида аналитики %1 указан неверный порядковый номер профиля распределения (должен быть перед профилем %2).';
												|en = 'Incorrect sequence number of the allocation profile is specified for the %1 dimension kind (must be before the %2 profile).'; fa = 'Incorrect sequence number of the allocation profile is specified for the %1 dimension kind (must be before the %2 profile).';
												|it = 'Incorrect sequence number of the allocation profile is specified for the %1 dimension kind (must be before the %2 profile).';
												|pl = 'Incorrect sequence number of the allocation profile is specified for the %1 dimension kind (must be before the %2 profile).';
												|tr = '%1 boyut türü için belirtilen dağıtım profili sıra numarası yanlıştır (%2 profilinden önce olmalıdır).'");
		ErrorTextMissingIterationNumber = NStr("vi = 'Không có hồ sơ phân bổ với số thứ tự %1';
												|ru = 'Отсутствует профиль распределения с порядковым номером %1';
												|en = 'No allocation profile with sequence number %1'; fa = 'No allocation profile with sequence number %1';
												|it = 'No allocation profile with sequence number %1';
												|pl = 'No allocation profile with sequence number %1';
												|tr = '%1 sıra numarası olan dağıtım profili eksik'");
		ProfileIterationNumbers = DimensionFillingSettings.Unload(, "AllocationProfile, IterationNumber");
		ProfileIterationNumbers.GroupBy("AllocationProfile, IterationNumber");
		ProfileIterationNumbers.Sort("IterationNumber");
		CurrentIterationNumber = 1;
		VerifiedProfiles = New Array;
		For Each AllocationProfile In ProfileIterationNumbers Do
			If Not ValueIsFilled(AllocationProfile.AllocationProfile)
				Or Not ValueIsFilled(AllocationProfile.IterationNumber) Then
				Continue;
			ElsIf AllocationProfile.IterationNumber <> CurrentIterationNumber Then
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTextMissingIterationNumber, CurrentIterationNumber), , , , Cancel);
			EndIf;
			For Each KeyAndValue In TypesOfProfileAnalytics.Get(AllocationProfile.AllocationProfile) Do
				If Not ValueIsFilled(KeyAndValue.Value) Then
					Continue;
				EndIf;
				SettingString = DimensionFillingSettings.Find(KeyAndValue.Value, "DimensionKind");
				If SettingString.FillingMethod = Enums.MethodsOfFillingBudgetFlowItemDimensions.ByAllocationProfile
					And SettingString.AllocationProfile <> AllocationProfile.AllocationProfile
					And VerifiedProfiles.Find(SettingString.AllocationProfile) = Undefined Then
					Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
						ErrorTextInvalidIterationNumber, SettingString.DimensionKind, AllocationProfile.AllocationProfile));
				EndIf;
			EndDo;
			VerifiedProfiles.Add(SettingString.AllocationProfile);
			CurrentIterationNumber = CurrentIterationNumber + 1;
		EndDo;
		
	EndIf;
	
	If Not Cancel And VerificationOfUseOfCalculationRuleIsRequiredBeforeRecording() Then
		Query = New Query;
		Query.SetParameter("Rule", Ref);
		Query.Text = 
		"SELECT TOP 1
		|	CalculationsRules.Ref AS Ref
		|FROM
		|	Catalog.FinancialReportItems.CalculationsRules AS CalculationsRules
		|WHERE
		|	CalculationsRules.Rule = &Rule";
		If Not Query.Execute().IsEmpty() Then
			Common.MessageToUser(NStr("vi = 'Quy tắc tính toán này đã được sử dụng trong các tùy chỉnh khoản mục ngân sách.';
										|ru = 'Данное правило расчета уже используется в настройках видов бюджетов.';
										|en = 'This calculation rule is already used in the budget profile settings.'; fa = 'This calculation rule is already used in the budget profile settings.';
										|it = 'This calculation rule is already used in the budget profile settings.';
										|pl = 'This calculation rule is already used in the budget profile settings.';
										|tr = 'Bu hesaplama kuralı bütçe profillerinin ayarlarında zaten kullanılmaktadır.'"), , , , Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then 
		Return;
	EndIf;
	
	If Not IsNew() And TypeOf(Receiver) = Type("CatalogRef.BudgetBalanceItems") And Common.ObjectAttributeValue(
		Receiver, "IndicatorType") = Enums.BudgetBalanceItemType.Estimated_ Then
		CheckingForChangesToCommunicationRule();
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsNew() Then
		ObjectReference = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.GetRef();
		SetNewObjectRef(ObjectReference);
	EndIf;
	
	If Status = Enums.BudgetingRuleStatuses.Valid And Not DeletionMark Then
		RequestByRule = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.GetRequestForPaymentRulesSettings(
			ThisObject);
	Else
		RequestByRule = Undefined;
	EndIf;
	RequestStorage = New ValueStorage(RequestByRule);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then 
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Rule", Ref);
	Query.Text = 
		"SELECT DISTINCT
		|	NestedQuery.BudgetProfile AS BudgetProfile
		|FROM
		|	(SELECT
		|		FinancialReportItems.Owner AS BudgetProfile
		|	FROM
		|		Catalog.FinancialReportItems AS FinancialReportItems
		|	WHERE
		|		FinancialReportItems.Owner REFS Catalog.BudgetProfiles
		|		AND TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					Catalog.FinancialReportItems.CalculationsRules AS FinancialReportItemsCalculationsRules
		|				WHERE
		|					FinancialReportItemsCalculationsRules.Ref = FinancialReportItems.Ref
		|					AND FinancialReportItemsCalculationsRules.Rule = &Rule)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		BudgetProfilesItemAndIndicatorCache.Ref
		|	FROM
		|		Catalog.BudgetProfiles.ItemAndIndicatorCache AS BudgetProfilesItemAndIndicatorCache
		|	WHERE
		|		CAST(BudgetProfilesItemAndIndicatorCache.ItemIndicator AS Catalog.BudgetBalanceItems).IndicatorType = VALUE(Enum.BudgetBalanceItemType.Estimated_)
		|		AND TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS RuleForCalculatingRelatedBudgetBalancesAndTurnovers
		|				WHERE
		|					BudgetProfilesItemAndIndicatorCache.ItemIndicator = RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Receiver)) AS NestedQuery";
	Selection = Query.Execute().Select();
	
	RuleForCalculatedIndicator = (TypeOf(Receiver) = Type("CatalogRef.BudgetBalanceItems")
		And Common.ObjectAttributeValue(Receiver, "IndicatorType")
		= Enums.BudgetBalanceItemType.Estimated_);
	
	RecordSet = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.CreateRecordSet();
	RecordSet.Filter.CacheKind.Set(Enums.BudgetCacheKinds.CompositionSchemas);
	If Not RuleForCalculatedIndicator Then
		RecordSet.Filter.GenerationMode.Set(Enums.ModesOfBudgetReportGeneration.FillType);
	EndIf;
	
	While Selection.Next() Do
		RecordSet.Filter.BudgetProfile.Set(Selection.BudgetProfile);
		RecordSet.Write();
	EndDo;
	
	If RuleForCalculatedIndicator Then
		Selection.Reset();
		RecordSet.Filter.CacheKind.Set(Enums.BudgetCacheKinds.StructureOfBudgetProfileDescription);
		While Selection.Next() Do
			RecordSet.Filter.BudgetProfile.Set(Selection.BudgetProfile);
			RecordSet.Write();
		EndDo;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	RequestStorage = New ValueStorage(Undefined);
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckingForChangesToCommunicationRule()
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("CurSource", Source);
	Query.SetParameter("CurrentDestination", Receiver);
	Query.SetParameter("CalculationRule", Ref);
	Query.Text =
	"SELECT
	|	CAST(&CurSource AS Catalog.BudgetFlowItems) AS BudgetFlowItem,
	|	CAST(&CurrentDestination AS Catalog.BudgetBalanceItems) AS BudgetBalanceItem
	|INTO CurRecords
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(CalculationsRules.Source AS Catalog.BudgetFlowItems) AS BudgetFlowItem,
	|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems) AS BudgetBalanceItem
	|INTO PreviousEntries
	|FROM
	|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|WHERE
	|	CAST(CalculationsRules.Receiver AS
	|		Catalog.BudgetBalanceItems).IndicatorType = VALUE(Enum.BudgetBalanceItemType.Estimated_)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PreviousEntries.BudgetFlowItem AS ItemIndicator
	|INTO VerificationObjects
	|FROM
	|	PreviousEntries AS PreviousEntries
	|		INNER JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|		ON PreviousEntries.BudgetFlowItem = ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem
	|		AND ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults
	|		AND NOT ActualDataQueryRulesByBudgetFlowItems.DeletionMark
	|
	|UNION
	|
	|SELECT
	|	CurRecords.BudgetFlowItem AS ItemIndicator
	|FROM
	|	CurRecords AS CurRecords
	|		INNER JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|		ON CurRecords.BudgetFlowItem = ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem
	|		AND ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults
	|		AND NOT ActualDataQueryRulesByBudgetFlowItems.DeletionMark
	|
	|UNION
	|
	|SELECT
	|	PreviousEntries.BudgetBalanceItem
	|FROM
	|	PreviousEntries AS PreviousEntries
	|		INNER JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|		ON PreviousEntries.BudgetFlowItem = ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem
	|		AND ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults
	|		AND NOT ActualDataQueryRulesByBudgetFlowItems.DeletionMark
	|
	|UNION
	|
	|SELECT
	|	CurRecords.BudgetBalanceItem
	|FROM
	|	CurRecords AS CurRecords
	|		INNER JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|		ON CurRecords.BudgetFlowItem = ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem
	|		AND ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults
	|		AND NOT ActualDataQueryRulesByBudgetFlowItems.DeletionMark
	|
	|INDEX BY
	|	ItemIndicator";
	
	ClearCacheByBudgetType = False;
	
	Results = Query.ExecuteBatch();
	
	RulesTable = Results[2].Unload();
	If RulesTable.Count() > 0
		And RulesTable[0].Count <> 0 Then
		
		ClearCacheByBudgetType = True;
	EndIf;
	If ClearCacheByBudgetType Then
		
		Query.Text =
		"SELECT DISTINCT
		|	Table.Ref AS BudgetProfile
		|FROM
		|	Catalog.BudgetProfiles.ItemAndIndicatorCache AS Table
		|WHERE
		|	Table.ItemIndicator IN
		|			(SELECT
		|				VerificationObjects.ItemIndicator
		|			FROM
		|				VerificationObjects)";
		
		Selection = Query.Execute().Select();
		
		SetPrivilegedMode(True);
		
		While Selection.Next() Do
			RecruitmentByBudgetType = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.CreateRecordSet();
			RecruitmentByBudgetType.Filter.BudgetProfile.Set(Selection.BudgetProfile);
			RecruitmentByBudgetType.Write(True);
		EndDo;
		
	EndIf;
	
EndProcedure

Function VerificationOfUseOfCalculationRuleIsRequiredBeforeRecording()
	
	If IsNew() Then
		Return False;
	EndIf;
	
	InitialAttributesOfRule = Common.ObjectAttributesValues(Ref,
		"Receiver, RecordCalculationInPlanningDocuments");
	
	Return Receiver <> InitialAttributesOfRule.Receiver
		Or RecordCalculationInPlanningDocuments <> InitialAttributesOfRule.RecordCalculationInPlanningDocuments;
	
EndFunction

#EndRegion

#EndIf
