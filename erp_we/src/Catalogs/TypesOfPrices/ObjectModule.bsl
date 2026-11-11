#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If PriceRoundingRules.Count() > 1 Then
		PriceRoundingRules.Sort("LowerBoundOfPriceRange");
	EndIf;
	
	If ValueIsFilled(DataCompositionSchema) Then
		StorageOfDataCompositionSchema = Undefined;
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralPriceTypes") Then
		SetPrivilegedMode(True);
		Query = New Query(
		"SELECT TOP 1
		|	TypesOfPrices.Ref
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	TypesOfPrices.Ref <> &Ref");
		Query.SetParameter("Ref", Ref);
		If Not Query.Execute().IsEmpty() Then
			Constants.UseSeveralPriceTypes.Set(True);
		EndIf;
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	RefreshReusableValues()
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If Not IsFolder Then
		Id = "";
	EndIf;
	
EndProcedure

Function AdvancedRoundingSettingsAreUsed()
	
	UseAdvancedRoundingSetting = False;
	
	If PriceRoundingRules.Count() = 1
		And PriceRoundingRules[0].LowerBoundOfPriceRange = 0
		And PriceRoundingRules[0].SmartRounding = 0 Then
		UseAdvancedRoundingSetting = False;
	ElsIf PriceRoundingRules.Count() >= 1 Then
		UseAdvancedRoundingSetting = True;
	Else
		UseAdvancedRoundingSetting = False;
	EndIf;
	
	Return UseAdvancedRoundingSetting;
	
EndFunction

Function AdvancedFeaturesAreUsed()
	
	UseAdvancedFeatures = False;
	
	If AdvancedRoundingSettingsAreUsed() Then
		UseAdvancedFeatures = True;
	EndIf;
	
	If Not ValueIsFilled(DataCompositionSchema) Or StorageOfDataCompositionSettings.Get() <> Undefined Then
		UseAdvancedFeatures = True;
	EndIf;
	
	If PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseData")
		Or PricingMethod = PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes") Then
		UseAdvancedFeatures = True;
	EndIf;
	
	If Thresholds.Count() > 0 Then
		UseAdvancedFeatures = True;
	EndIf;
	
	If PriceGroups.Count() > 0 Then
		UseAdvancedFeatures = True;
	EndIf;
	
	Return UseAdvancedFeatures;
	
EndFunction

Procedure Filling(FillingData, StandardProcessing)
	
	If Not IsFolder Then
		FillInDefaultValues();
	EndIf;
	
	If IsNew() And Not IsFolder And Not GetFunctionalOption("UseMultipleCurrencies") Then
		PriceCurrency = Catalogs.Currencies.GetDefaultCurrency();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not IdentifierIsUnique() Then
		CommonClientServer.MessageToUser(
			StrReplace(NStr("vi = 'Trong cơ sở dữ liệu đã có sẵn dạng giá với tên định danh %Id%"". Tên định danh phải là đơn trị';
							|ru = 'В базе данных уже содержится вид цены с идентификатором ""%Id%"". Идентификатор должен быть уникальным';
							|en = 'Price type with ID ""%Id%"" already exists in the infobase. ID must be unique'; fa = 'Price type with ID ""%Id%"" already exists in the infobase. ID must be unique';
							|it = 'Nel database esiste già un tipo di prezzo con l''identificatore ""%Id%"". L''identificatore deve essere univoco';
							|pl = 'W bazie danych istnieje już rodzaj ceny z identyfikatorem ""%Id%"". Identyfikator musi być unikalny';
							|tr = 'Veri tabanı zaten ""%Id%"" tanımlayıcısına sahip fiyat türü içermektedir. Kimlik, benzersiz olmalıdır'"), "%Id%", Id), 
			ThisObject, "Id",, Cancel);
	EndIf;
	
	If PricingMethod = Enums.PriceSettingMethods.AnotherPriceTypeMarkup
		And BasicPriceType = Ref Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Dạng giá cơ bản không thể bằng dạng giá hiện tại';
				|ru = 'Базовый вид цены не может быть равен текущему виду цены';
				|en = 'Basic price type cannot be equal to the current price type'; fa = 'Basic price type cannot be equal to the current price type';
				|it = 'Il tipo di prezzo base non può essere uguale al tipo di prezzo corrente';
				|pl = 'Podstawowy rodzaj ceny nie może pokrywać się z bieżącym rodzajem ceny';
				|tr = 'Taban fiyat türü, mevcut fiyat türüne eşit olamaz'"),
			ThisObject, "BasicPriceType",, Cancel);
	EndIf;
		
	If Status = Enums.StatusesOfPriceTypeValidity.NotValid And TypeOfPricesUsed() Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Không thể đặt trạng thái ""Không hiệu lực"" bởi vì dạng giá đang được dùng trong các dạng giá khác';
				|ru = 'Статус ""Не действует"" не может быть установлен, т.к. вид цен используется в других видах цен';
				|en = 'The ""Not valid"" status cannot be set because the price type is used in other price types'; fa = 'The ""Not valid"" status cannot be set because the price type is used in other price types';
				|it = 'Lo stato ""Non valido"" non può essere impostato, perché il tipo di prezzo viene utilizzato in altri tipi di prezzi';
				|pl = 'Status ""Nieaktualna"" nie może zostać ustawiony, ponieważ rodzaj cen jest wykorzystywany w innych rodzajach cen';
				|tr = 'Fiyat türü, diğer fiyat türlerinde kullanıldığı için ""Geçerli değil"" durumu ayarlanamaz'"),
			ThisObject, "Status",, Cancel);
		
	EndIf;
	
	If Status = Enums.StatusesOfPriceTypeValidity.Valid 
		And InfluencingPriceTypes.Count() > 0 And InfluencingTypesOfPricesDoNotWork() Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Không thể đặt trạng thái ""Có hiệu lực"" vì dạng giá này phụ thuộc vào các dạng giá không có hiệu lực';
				|ru = 'Статус ""Действует"" не может быть установлен, т.к. данный вид цен зависит от недействующих видов цен';
				|en = 'The ""Valid"" status cannot be set because this price type depends on invalid price types'; fa = 'The ""Valid"" status cannot be set because this price type depends on invalid price types';
				|it = 'Lo stato ""Valido"" non può essere impostato, perché questo tipo di prezzo dipende dai tipi di prezzi inattivi';
				|pl = 'Status ""Aktualna"" nie może zostać ustawiony, ponieważ rodzaj cen zależy od nieaktualnych rodzajów cen';
				|tr = 'Bu fiyat türü, geçersiz fiyat türlerine bağlı olduğundan dolayı ""Aktif"" durumu ayarlanamaz'"),
			ThisObject,,, Cancel);
			
	EndIf;
	
	If Status = Enums.StatusesOfPriceTypeValidity.Valid
		And Not UserRightsCached.PriceTypeApproval()
		And Enums.PriceSettingMethods.ThisIsUnsafeWayToSetPrice(PricingMethod) Then
		ErrorText = NStr("vi = 'Không có quyền thiết lập trạng thái ""Có hiệu lực"" đối với phương pháp xác định giá này.
		|Hãy lưu dạng giá với trạng thái khác và liên hệ với người sử dụng có vai trò ""Xác nhận dạng giá"" hoặc người quản trị.';
		|ru = 'Нет прав на установку статуса ""Действует"" для данного способа задания цены.
		|Сохраните вид цены с другим статусом и обратитесь к пользователю с ролью ""Утверждение видов цен"" или администратору.';
		|en = 'You have insufficient rights to set the ""Valid"" status for this pricing method.
		|Save the price type with a different status and contact a user with the ""Price type approval"" role or an administrator.'; fa = 'You have insufficient rights to set the ""Valid"" status for this pricing method.
		|Save the price type with a different status and contact a user with the ""Price type approval"" role or an administrator.';
		|it = 'You have insufficient rights to set the ""Valid"" status for this pricing method.
		|Save the price type with a different status and contact a user with the ""Price type approval"" role or an administrator.';
		|pl = 'You have insufficient rights to set the ""Valid"" status for this pricing method.
		|Save the price type with a different status and contact a user with the ""Price type approval"" role or an administrator.';
		|tr = 'Bu fiyat belirleme yöntemi için ""Geçerli"" durumunu ayarlama izniniz yok.
		|Fiyat görünümünü farklı bir durumda iken kaydedin ve ""Fiyat türleri onayı"" rolüne sahip bir kullanıcıyla veya bir yöneticiyle irtibata geçin.'");
		Common.MessageToUser(ErrorText, ThisObject, "Status",, Cancel);
	EndIf;
	
	For IndexOf = 0 To PriceRoundingRules.Count() - 1 Do
		
		StringOfRoundingRules = PriceRoundingRules[IndexOf];
		UpperBoundOfRange = ?(IndexOf < PriceRoundingRules.Count() - 1, PriceRoundingRules[IndexOf + 1].LowerBoundOfPriceRange, -1);
		CheckCorrectnessOfRoundingRulesForPriceInLine(StringOfRoundingRules, UpperBoundOfRange, Cancel);
		
	EndDo;
	
	NotCheckedAttributeArray = New Array;
	If PricingMethod <> Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes Then
		NotCheckedAttributeArray.Add("Formula");
		NotCheckedAttributeArray.Add("PriceGroups.Formula");
	EndIf;
	
	If PricingMethod <> Enums.PriceSettingMethods.AnotherPriceTypeMarkup Then
		NotCheckedAttributeArray.Add("BasicPriceType");
		NotCheckedAttributeArray.Add("PriceGroups.BasicPriceType");
		NotCheckedAttributeArray.Add("PriceGroups.Markup");
	EndIf;
	
	NotCheckedAttributeArray.Add("Markup");
	
	UseAdvancedPricingFeatures = AdvancedFeaturesAreUsed();
	UseArbitraryDataCompositionSchemas = Not Common.DataSeparationEnabled() And UseAdvancedPricingFeatures;
	
	If UseArbitraryDataCompositionSchemas Then
		NotCheckedAttributeArray.Add("DataCompositionSchema");
	EndIf;
	
	If Not UseAdvancedPricingFeatures Then
		NotCheckedAttributeArray.Add("DataCompositionSchema");
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		NotCheckedAttributeArray.Add("PriceCurrency");
	EndIf;
	
	If Not IsFolder Then
		
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
		If UsePriceManagementSystem25
				And (UseForWholesaleToCustomers Or UseForIntercompanySales) Then
					
			CheckedAttributes.Add("OptionForSpecifyingVATRates");
			If OptionForSpecifyingVATRates = Enums.OptionsForSpecifyingVATRatesInPriceList.SpecifyVATRateForAllItems Then
				CheckedAttributes.Add("VATRate");
			EndIf;
			
			If GetFunctionalOption("UseMultiCountryAccounting") Then
				If Not OptionForSpecifyingVATRates = Enums.OptionsForSpecifyingVATRatesInPriceList.NotSpecifiedVATRates Then
					CheckedAttributes.Add("Country");
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInDefaultValues()
	
	DataCompositionSchema = "Typical";
	PriceCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(PriceCurrency);
	OptionForSpecifyingVATRates = Enums.OptionsForSpecifyingVATRatesInPriceList.NotSpecifiedVATRates;
	Country = SettingsValueClientServerCached.MainCountry();
	
	If UserRightsCached.PriceTypeApproval()
		Or Not GetFunctionalOption("UseSeveralPriceTypes") Then
		// "Valid" is set only for a user with sufficient rights
		// or if there are no other price types
		Status = Enums.StatusesOfPriceTypeValidity.Valid;
	Else
		Status = Enums.StatusesOfPriceTypeValidity.NotValid;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Searches for an ID that matches the one filled in in the object
//
// Returns:
//	Boolean - True if the ID is not found
//	         False - otherwise.
//
Function IdentifierIsUnique()
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.Text = "
		|SELECT
		|	1 AS Field1
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	TypesOfPrices.Id = &Id
		|	AND TypesOfPrices.Ref <> &Ref";
		
	Query.SetParameter("Ref",        Ref);
	Query.SetParameter("Id", Id);
	
	Return Query.Execute().IsEmpty();
	
EndFunction

// Searches for links to a price type in other price types
//
// Returns:
//	Boolean - True if the price type is used
//	         False - otherwise.
Function TypeOfPricesUsed()
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.Text = "
		|SELECT
		|	1 AS Field1
		|FROM
		|	Catalog.TypesOfPrices.InfluencingPriceTypes AS InfluencingPriceTypes
		|WHERE
		|	InfluencingPriceTypes.InfluencingPriceType = &Ref
		|	AND InfluencingPriceTypes.Ref.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)
		|	AND InfluencingPriceTypes.Ref <> &Ref";
		
	Query.SetParameter("Ref", Ref);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Searches for links to a price type in other price types
//
// Returns:
//	Boolean - True if the price type is used
//	         False - otherwise.
//
Function InfluencingTypesOfPricesDoNotWork()
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.Text = "
		|SELECT
		|	1 AS Field1
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	InfluencingPriceTypes.Ref.Status = VALUE(Enum.StatusesOfPriceTypeValidity.NotValid)
		|	AND TypesOfPrices.Ref IN (&TypesOfPrices)";
		
	Query.SetParameter("TypesOfPrices", InfluencingPriceTypes.UnloadColumn("InfluencingPriceType"));
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Checks the correctness of the rounding rules in the PM line of the price rule.
//
// Parameters:
//	StringOfRoundingRules  - String - The row in the table part of the Price round rule:
//		* LineNumber - Number - line number of the table part
//		* LowerBoundOfPriceRange - DefinedType.MonetaryAmountNonNegative - Lower limit of the price range
//		* RoundingPrecision - DefinedType.MonetaryAmountNonNegative - Rounding accuracy
//		* SmartRounding - DefinedType.MonetaryAmountNonNegative - Psychological rounding
//	UpperBoundOfRange - Number - value of the upper limit of the price range
//	Cancel                   - Boolean - indicates that the rounding rules are incorrect.
//
Procedure CheckCorrectnessOfRoundingRulesForPriceInLine(Val StringOfRoundingRules, Val UpperBoundOfRange, Cancel) Export
	
	If ValueIsFilled(StringOfRoundingRules.RoundingPrecision) And UpperBoundOfRange > 0 
		And StringOfRoundingRules.RoundingPrecision >= UpperBoundOfRange Then
		
		ErrorText = NStr("vi = 'Phần thập phân làm tròn trong dòng %LineNumber% danh sách ""Quy tắc làm tròn đơn giá"" phải nhỏ hơn biên dưới của khoảng giá trong dòng tiếp theo';
						|ru = 'Точность округления в строке %LineNumber% списка ""Правила округления цены"" должна быть меньше нижней границы диапазона цен в следующей строке';
						|en = 'Rounding precision in line %LineNumber% of the ""Price rounding rules"" list must be less than the lower bound of the price range in the next line'; fa = 'Rounding precision in line %LineNumber% of the ""Price rounding rules"" list must be less than the lower bound of the price range in the next line';
						|it = 'La precisione di arrotondamento nella riga %LineNumber% dell''elenco ""Regole di arrotondamento dei prezzi"" deve essere inferiore al limite inferiore dell''intervallo di prezzo nella riga successiva';
						|pl = 'Dokładność zaokrąglenia w wierszu %LineNumber% listy ""Правила округления цены"" musi być mniejsza od dolnej granicy zakresu cen w następnym wierszu';
						|tr = '""Fiyat Yuvarlama Kuralları"" listesinin %LineNumber% satırındaki yuvarlama duyarlılığı, bir sonraki satırdaki fiyat aralığının alt sınırından küçük olmalıdır'");
		ErrorText = StrReplace(ErrorText, "%LineNumber%", StringOfRoundingRules.LineNumber);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			CommonClientServer.PathToTabularSection("PriceRoundingRules", StringOfRoundingRules.LineNumber, "RoundingPrecision"),
			,
			Cancel);
		
	EndIf;
	
	If ValueIsFilled(StringOfRoundingRules.SmartRounding) 
		And UpperBoundOfRange > 0 And StringOfRoundingRules.SmartRounding >= UpperBoundOfRange Then
		
		ErrorText = NStr("vi = 'Làm tròn tâm lý trong dòng %LineNumber% danh sách ""Quy tắc làm tròn đơn giá"" phải nhỏ hơn biên dưới của khoảng giá trong dòng tiếp theo';
						|ru = 'Психологическое округление в строке %LineNumber% списка ""Правила округления цены"" должно быть меньше нижней границы диапазона цен в следующей строке';
						|en = 'Smart rounding in line %LineNumber% of the ""Price rounding rules"" list must be less than the lower bound of the price range in the next line'; fa = 'Smart rounding in line %LineNumber% of the ""Price rounding rules"" list must be less than the lower bound of the price range in the next line';
						|it = 'Arrotondamento psicologico nella riga %LineNumber% dell''elenco ""Regole di arrotondamento dei prezzi"" deve essere inferiore al limite inferiore dell''intervallo di prezzo nella riga successiva';
						|pl = 'Psychologiczne zaokrąglenie w wierszu %LineNumber% listy ""Правила округления цены"" musi być mniejsza od dolnej granicy zakresu cen w następnym wierszu';
						|tr = '""Fiyat Yuvarlama Kuralları"" listesinin %LineNumber% satırındaki psikolojik yuvarlama, bir sonraki satırdaki fiyat aralığının alt sınırından küçük olmalıdır'");
		ErrorText = StrReplace(ErrorText, "%LineNumber%", StringOfRoundingRules.LineNumber);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			CommonClientServer.PathToTabularSection("PriceRoundingRules", StringOfRoundingRules.LineNumber, "SmartRounding"),
			,
			Cancel);
		
	EndIf;
	
	If ValueIsFilled(StringOfRoundingRules.RoundingPrecision) And
		StringOfRoundingRules.SmartRounding >= StringOfRoundingRules.RoundingPrecision Then
		
		ErrorText = NStr("vi = 'Làm tròn tâm lý trong dòng %LineNumber% danh sách ""Quy tắc làm tròn đơn giá"" phải nhỏ hơn phần thập phân làm tròn';
						|ru = 'Психологическое округление в строке %LineNumber% списка ""Правила округления цены"" должно быть меньше точности округления';
						|en = 'Smart rounding in line %LineNumber% of the ""Price rounding rules"" list must be less than the rounding precision'; fa = 'Smart rounding in line %LineNumber% of the ""Price rounding rules"" list must be less than the rounding precision';
						|it = 'Arrotondamento psicologico nella riga %LineNumber% dell''elenco ""Regole di arrotondamento dei prezzi"" deve essere inferiore alla precisione di arrotondamento';
						|pl = 'Psychologiczne zaokrąglenie w wierszu %LineNumber% listy ""Reguły zaokrąglania cen"" musi być mniejsza od dokładności zaokrąglenia';
						|tr = '""Fiyat Yuvarlama Kuralları"" listesinin %LineNumber% satırındaki psikolojik yuvarlama, yuvarlama duyarlılığından küçük olmalıdır'");
		ErrorText = StrReplace(ErrorText, "%LineNumber%", StringOfRoundingRules.LineNumber);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			CommonClientServer.PathToTabularSection("PriceRoundingRules", StringOfRoundingRules.LineNumber, "SmartRounding"),
			,
			Cancel);
		
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndIf
