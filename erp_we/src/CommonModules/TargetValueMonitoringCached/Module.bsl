////////////////////////////////////////////////////////////////////////////////
// THE MODULE CONTAINS PROCEDURES FOR OBTAINING VARIABLES TO FORM THE UPR. REPORT.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the layout of the electronic form for indicator analysis
//
// Returns:
//  SpreadsheetDocument - layout of a tabular document.
//
Function TemplateIndicatorPages() Export
	
	Var TemplateIndicatorPages;
	
	TemplateIndicatorPages = Reports.PerformanceDashboard.GetTemplate("TemplateIndicatorPages");
	
	Return TemplateIndicatorPages;
	
EndFunction

// Returns the layout of the electronic form for indicator analysis
//
// Returns:
//  SpreadsheetDocument - layout of a tabular document.
//
Function GetStateMatrix() Export
	
	TemplateMatrixOfStatesOfIndicators = Reports.PerformanceDashboard.GetTemplate("IndicatorStateMatrix");
	TemplateMatrixOfStatesOfIndicators.LanguageCode = ConfigurationLanguageCode();
	
	Return TemplateMatrixOfStatesOfIndicators;
	
EndFunction

// Returns a string representation of the trend explanation in the current user's language.
//
// Parameters:
//  ExplanationOfTheTrend - String - A string explanation of the trend from the layout of the matrix of States.
// 
// Returns:
//  String - A line explaining the trend in the language of the current user.
//
Function PresentationExplanationOfTrendOfStateMatrix(ExplanationOfTheTrend) Export
	Presentation = "";
	If ExplanationOfTheTrend = "NoChangesFromThePreviousValue" Then
		Presentation = NStr("vi = 'Không thay đổi so với giá trị trước đó';
							|ru = 'Без изменений по сравнению с предыдущим значением';
							|en = 'Without changes compared to the previous value'; fa = 'Without changes compared to the previous value';
							|it = 'Senza variazioni in confronto al valore precedente';
							|pl = 'Bez zmian w stosunku do poprzedniej wartości.';
							|tr = 'Önceki değerden değişiklik yok'");
	ElsIf ExplanationOfTheTrend = "ValuesDecreaseInTheOppositeDirectionToTheEstablishedTrend" Then
		Presentation = NStr("vi = 'Giá trị giảm xuống. Ngược hướng với xu hướng đã đặt';
							|ru = 'Значения уменьшаются. Направление противоположное установленному тренду';
							|en = 'Values are decreased. The direction is the opposite to the set trend'; fa = 'Values are decreased. The direction is the opposite to the set trend';
							|it = 'I valori diminuiscono. La direzione è contraria rispetto alla tendenza stabilita';
							|pl = 'Wartości zmniejszają się. Kierunek przeciwny do ustalonego trendu';
							|tr = 'Değerler azalıyor. Yerleşik trendin tersi yönü'");
	ElsIf ExplanationOfTheTrend = "TheValuesIncreaseTheDirectionCorrespondsToTheEstablishedTrend" Then
		Presentation = NStr("vi = 'Giá trị tăng lên. Cùng hướng với xu hướng đã đặt';
							|ru = 'Значения увеличиваются. Направление соответствует установленному тренду';
							|en = 'Values increase. The direction matches the set trend'; fa = 'Values increase. The direction matches the set trend';
							|it = 'I valori crescono. La direzione corrisponde alla tendenza stabilita';
							|pl = 'Wartości powiększają się. Kierunek odpowiada ustalonemu trendu';
							|tr = 'Değerler artıyor. Yerleşik trende uygun yön'");
	ElsIf ExplanationOfTheTrend = "ValuesAreReduced" Then
		Presentation = NStr("vi = 'Giá trị giảm xuống';
							|ru = 'Значения уменьшаются';
							|en = 'Values are decreased'; fa = 'Values are decreased';
							|it = 'I valori diminuiscono';
							|pl = 'Wartości zmniejszają się';
							|tr = 'Değerler azalıyor'");
	ElsIf ExplanationOfTheTrend = "ValuesIncrease" Then
		Presentation = NStr("vi = 'Giá trị tăng lên';
							|ru = 'Значения увеличиваются';
							|en = 'Values increase'; fa = 'Values increase';
							|it = 'I valori crescono';
							|pl = 'Wzrost wartości';
							|tr = 'Değerler artıyor'");
	ElsIf ExplanationOfTheTrend = "CharacterChangeUndefined" Then
		Presentation = NStr("vi = 'Chưa xác định đặc điểm thay đổi';
							|ru = 'Характер изменений неопределен';
							|en = 'Change nature is uncertain'; fa = 'Change nature is uncertain';
							|it = 'Il carattere di modifica non è definito';
							|pl = 'Charakter zmian nie jest określony';
							|tr = 'Değişikliklerin karakteri tanımlanmadı'");
	ElsIf ExplanationOfTheTrend = "TheValuesDecreaseAndTheDirectionCorrespondsToTheEstablishedTrend" Then
		Presentation = NStr("vi = 'Giá trị giảm xuống. Cùng hướng với xu hướng đã đặt';
							|ru = 'Значения уменьшаются. Направление соответствует установленному тренду';
							|en = 'Values are decreased. The direction corresponds to the set trend'; fa = 'Values are decreased. The direction corresponds to the set trend';
							|it = 'I valori diminuiscono. La direzione corrisponde alla tendenza stabilita';
							|pl = 'Wartości zmniejszają się. Kierunek odpowiada ustalonemu trendu';
							|tr = 'Değerler azalıyor. Yerleşik trende uygun yön'");
	ElsIf ExplanationOfTheTrend = "ValuesIncreaseInTheOppositeDirectionToTheEstablishedTrend" Then
		Presentation = NStr("vi = 'Giá trị tăng lên. Ngược hướng với xu hướng đã đặt';
							|ru = 'Значения увеличиваются. Направление противоположное установленному тренду';
							|en = 'Values increase. The direction is opposite to the set trend'; fa = 'Values increase. The direction is opposite to the set trend';
							|it = 'I valori crescono. La direzione è contraria rispetto alla tendenza stabilita';
							|pl = 'Wartości powiększają się. Kierunek przeciwny do ustalonego trendu';
							|tr = 'Değerler artıyor. Yerleşik trendin tersi yönü'");
	ElsIf ExplanationOfTheTrend = "ValuesAreReducedWithinTheTargetRange" Then
		Presentation = NStr("vi = 'Giá trị giảm xuống trong phạm vi khoảng mục tiêu';
							|ru = 'Значения уменьшаются в пределах целевого диапазона';
							|en = 'Values are decreased within the target range'; fa = 'Values are decreased within the target range';
							|it = 'I valori diminuiscono entro i limiti dell''intervallo di obiettivi';
							|pl = 'Spadek wartości w zakresie docelowym';
							|tr = 'Değerler hedef aralık kapsamında azalıyor'");
	ElsIf ExplanationOfTheTrend = "ValuesIncreaseWithinTheTargetRange" Then
		Presentation = NStr("vi = 'Giá trị tăng trong phạm vi khoảng mục tiêu';
							|ru = 'Значения увеличиваются в пределах целевого диапазона';
							|en = 'Values increase within the limits of the target range'; fa = 'Values increase within the limits of the target range';
							|it = 'I valori crescono entro l''intervallo di obiettivi';
							|pl = 'Wzrost wartości w zakresie docelowym';
							|tr = 'Değerler hedef aralık kapsamında artıyor'");
	EndIf;
	
	Return Presentation;
EndFunction

// Returns a string representation of the status explanation in the current user's language.
//
// Parameters:
//  ExplanationOfTheStatus - String - A string explanation of the status of the layout of the matrix of States.
// 
// Returns:
//  String - A string explaining the status in the language of the current user.
//
Function PresentationOfExplanationOfStatusOfStateMatrix(ExplanationOfTheStatus) Export
	Presentation = "";
	If ExplanationOfTheStatus = "TheGoalIsAchieved" Then
		Presentation = NStr("vi = 'Đã đạt mục tiêu';
							|ru = 'Цель достигнута';
							|en = 'Target is achieved'; fa = 'هدف محقق شده است';
							|it = 'Obiettivo raggiunto';
							|pl = 'Cel osiągnięty';
							|tr = 'Hedefe ulaşıldı'");
	ElsIf ExplanationOfTheStatus = "AcceptableIndicatorState" Then
		Presentation = NStr("vi = 'Tình trạng chỉ số chấp nhận được';
							|ru = 'Приемлемое состояние показателя';
							|en = 'Acceptable indicator state'; fa = 'Acceptable indicator state';
							|it = 'Stato accettabile dell''indice';
							|pl = 'Dopuszczalny stan wskaźnika';
							|tr = 'Göstergenin kabul edilebilir durumu'");
	ElsIf ExplanationOfTheStatus = "UnacceptableIndicatorState" Then
		Presentation = NStr("vi = 'Trạng thái số liệu không được chấp nhận';
							|ru = 'Неприемлемое состояние показателя';
							|en = 'Unacceptable indicator state'; fa = 'Unacceptable indicator state';
							|it = 'Stato inammissibile dell''indice';
							|pl = 'Niedopuszczalny stan wskaźnika';
							|tr = 'Göstergenin kabul edilemez durumu'");
	ElsIf ExplanationOfTheStatus = "TheStatusOfTheIndicatorIsNotDefined" Then
		Presentation = NStr("vi = 'Trạng thái chỉ báo không được xác định';
							|ru = 'Состояние показателя не определено';
							|en = 'Indicator state is not defined'; fa = 'Indicator state is not defined';
							|it = 'Lo stato dell''indice non è definito';
							|pl = 'Stan wskaźnika nie jest określony';
							|tr = 'Gösterge durumu tanımlanmadı'");
	ElsIf ExplanationOfTheStatus = "CalculatedWithErrors" Then
		Presentation = NStr("vi = 'Tính toán có lỗi';
							|ru = 'Рассчитано с ошибками';
							|en = 'Calculated with errors'; fa = 'محاسبه‌شده با خطا';
							|it = 'Calcolato con errori';
							|pl = 'Obliczono z błędami';
							|tr = 'Hatalarla hesaplandı'");
	EndIf;
	
	Return Presentation;
EndFunction

// Returns the "block Separator" area of the layout of the electronic form for indicator analysis.
//
// Returns:
//  SpreadsheetDocument - layout of the tabular document area of the document, for separating blocks of information.
//
Function GetSeparatorOfPrintedFormOfAnalysisVariant() Export
	
	Var BlockSeparator;
	
	TemplateForPrintedFormOfAnalysisVariant = TemplateIndicatorPages();
	BlockSeparator = TemplateForPrintedFormOfAnalysisVariant.GetArea("BlockSeparator");
	
	Return BlockSeparator;
	
EndFunction

#Region RgbhsvColorConversion

// Returns a table of matching web colors and component colors-red, green, and blue.
// 
// Returns:
//  ValueTable - the table of correspondence of web colors and constituent colors:
//   *WebColor_ - WebColors - color.
//   *Red - Number - The tone is red in RGB.
//   *Green - Number - The tone of the green color is RGB.
//   *B   - Number - The tone of the blue color is RGB.
//
Function ComponentsOfWebColors() Export
	
	Table = New ValueTable();
	Table.Columns.Add("WebColor_", New TypeDescription("Color"));
	Table.Columns.Add("Red", New TypeDescription("Number",,, New NumberQualifiers(3, 0, AllowedSign.Nonnegative)));
	Table.Columns.Add("Green", New TypeDescription("Number",,, New NumberQualifiers(3, 0, AllowedSign.Nonnegative)));
	Table.Columns.Add("B", New TypeDescription("Number",,, New NumberQualifiers(3, 0, AllowedSign.Nonnegative)));
	
	AddRecord(Table, WebColors.AliceBlue, 240, 248, 255);
	AddRecord(Table, WebColors.AntiqueWhite, 250, 235, 215);
	AddRecord(Table, WebColors.Aqua, 0, 255, 255);
	AddRecord(Table, WebColors.Aquamarine, 127, 255, 212);
	AddRecord(Table, WebColors.Azure, 240, 255, 255);
	AddRecord(Table, WebColors.Beige, 245, 245, 220);
	AddRecord(Table, WebColors.Bisque, 255, 228, 196);
	AddRecord(Table, WebColors.Black, 0, 0, 0);
	AddRecord(Table, WebColors.BlanchedAlmond, 255, 235, 205);
	AddRecord(Table, WebColors.Blue, 0, 0, 255);
	AddRecord(Table, WebColors.BlueViolet, 138, 43, 226);
	AddRecord(Table, WebColors.Brown, 165, 42, 42);
	AddRecord(Table, WebColors.BurlyWood, 222, 184, 135);
	AddRecord(Table, WebColors.CadetBlue, 95, 158, 160);
	AddRecord(Table, WebColors.Chartreuse, 127, 255, 0);
	AddRecord(Table, WebColors.Chocolate, 210, 105, 30);
	AddRecord(Table, WebColors.Coral, 255, 127, 80);
	AddRecord(Table, WebColors.CornFlowerBlue, 100, 149, 237);
	AddRecord(Table, WebColors.CornSilk, 255, 248, 220);
	AddRecord(Table, WebColors.Cream, 255, 251, 240);
	AddRecord(Table, WebColors.Crimson, 220, 20, 60);
	AddRecord(Table, WebColors.Cyan, 0, 255, 255);
	AddRecord(Table, WebColors.DarkBlue, 0, 0, 139);
	AddRecord(Table, WebColors.DarkCyan, 0, 139, 139);
	AddRecord(Table, WebColors.DarkGoldenRod, 184, 134, 11);
	AddRecord(Table, WebColors.DarkGray, 169, 169, 169);
	AddRecord(Table, WebColors.DarkGreen, 0, 100, 0);
	AddRecord(Table, WebColors.DarkKhaki, 189, 183, 107);
	AddRecord(Table, WebColors.DarkMagenta, 139, 0, 139);
	AddRecord(Table, WebColors.DarkOliveGreen, 85, 107, 47);
	AddRecord(Table, WebColors.DarkOrange, 255, 140, 0);
	AddRecord(Table, WebColors.DarkOrchid, 153, 50, 204);
	AddRecord(Table, WebColors.DarkRed, 139, 0, 0);
	AddRecord(Table, WebColors.DarkSalmon, 233, 150, 122);
	AddRecord(Table, WebColors.DarkSeaGreen, 143, 188, 143);
	AddRecord(Table, WebColors.DarkSlateBlue, 72, 61, 139);
	AddRecord(Table, WebColors.DarkSlateGray, 47, 79, 79);
	AddRecord(Table, WebColors.DarkTurquoise, 0, 206, 209);
	AddRecord(Table, WebColors.DarkViolet, 148, 0, 211);
	AddRecord(Table, WebColors.DeepPink, 255, 20, 147);
	AddRecord(Table, WebColors.DeepSkyBlue, 0, 191, 255);
	AddRecord(Table, WebColors.DimGray, 105, 105, 105);
	AddRecord(Table, WebColors.DodgerBlue, 30, 144, 255);
	AddRecord(Table, WebColors.FireBrick, 178, 34, 34);
	AddRecord(Table, WebColors.FloralWhite, 255, 250, 240);
	AddRecord(Table, WebColors.ForestGreen, 34, 139, 34);
	AddRecord(Table, WebColors.Fuchsia, 255, 0, 255);
	AddRecord(Table, WebColors.Gainsboro, 220, 220, 220);
	AddRecord(Table, WebColors.GhostWhite, 248, 248, 255);
	AddRecord(Table, WebColors.Gold, 255, 215, 0);
	AddRecord(Table, WebColors.Goldenrod, 218, 165, 32);
	AddRecord(Table, WebColors.Gray, 128, 128, 128);
	AddRecord(Table, WebColors.Green, 173, 255, 47);
	AddRecord(Table, WebColors.GreenYellow, 190, 190, 190);
	AddRecord(Table, WebColors.HoneyDew, 240, 255, 240);
	AddRecord(Table, WebColors.HotPink, 255, 105, 180);
	AddRecord(Table, WebColors.IndianRed, 205, 92, 92);
	AddRecord(Table, WebColors.Indigo, 75, 0, 130);
	AddRecord(Table, WebColors.Ivory, 255, 255, 240);
	AddRecord(Table, WebColors.Khaki, 240, 230, 140);
	AddRecord(Table, WebColors.Lavender, 230, 230, 250);
	AddRecord(Table, WebColors.LavenderBlush, 255, 240, 245);
	AddRecord(Table, WebColors.LawnGreen, 124, 252, 0);
	AddRecord(Table, WebColors.LemonChiffon, 255, 250, 205);
	AddRecord(Table, WebColors.LightBlue, 173, 216, 230);
	AddRecord(Table, WebColors.LightCoral, 240, 128, 128);
	AddRecord(Table, WebColors.LightCyan, 224, 255, 255);
	AddRecord(Table, WebColors.LightGoldenRod, 238, 221, 130);
	AddRecord(Table, WebColors.LightGoldenRodYellow, 250, 250, 210);
	AddRecord(Table, WebColors.LightGray, 211, 211, 211);
	AddRecord(Table, WebColors.LightGreen, 144, 238, 144);
	AddRecord(Table, WebColors.LightPink, 255, 182, 193);
	AddRecord(Table, WebColors.LightSalmon, 255, 160, 122);
	AddRecord(Table, WebColors.LightSeaGreen, 32, 178, 170);
	AddRecord(Table, WebColors.LightSkyBlue, 135, 206, 250);
	AddRecord(Table, WebColors.LightSlateBlue, 132, 112, 255);
	AddRecord(Table, WebColors.LightSlateGray, 119, 136, 153);
	AddRecord(Table, WebColors.LightSteelBlue, 176, 196, 222);
	AddRecord(Table, WebColors.LightYellow, 255, 255, 224);
	AddRecord(Table, WebColors.Lime, 0, 255, 0);
	AddRecord(Table, WebColors.LimeGreen, 50, 205, 50);
	AddRecord(Table, WebColors.Linen, 250, 240, 230);
	AddRecord(Table, WebColors.Magenta, 255, 0, 255);
	AddRecord(Table, WebColors.Maroon, 176, 48, 96);
	AddRecord(Table, WebColors.MediumAquaMarine, 102, 205, 170);
	AddRecord(Table, WebColors.MediumBlue, 0, 0, 205);
	AddRecord(Table, WebColors.MediumGray, 160, 160, 164);
	AddRecord(Table, WebColors.MediumGreen, 192, 220, 192);
	AddRecord(Table, WebColors.MediumOrchid, 186, 85, 211);
	AddRecord(Table, WebColors.MediumPurple, 147, 112, 219);
	AddRecord(Table, WebColors.MediumSeaGreen, 60, 179, 113);
	AddRecord(Table, WebColors.MediumSlateBlue, 123, 104, 238);
	AddRecord(Table, WebColors.MediumSpringGreen, 0, 250, 154);
	AddRecord(Table, WebColors.MediumTurquoise, 72, 209, 204);
	AddRecord(Table, WebColors.MediumVioletRed, 199, 21, 133);
	AddRecord(Table, WebColors.MidnightBlue, 25, 25, 112);
	AddRecord(Table, WebColors.MintCream, 245, 255, 250);
	AddRecord(Table, WebColors.MistyRose, 255, 228, 225);
	AddRecord(Table, WebColors.Moccasin, 255, 228, 181);
	AddRecord(Table, WebColors.NavajoWhite, 255, 222, 173);
	AddRecord(Table, WebColors.Navy, 0, 0, 128);
	AddRecord(Table, WebColors.OldLace, 253, 245, 230);
	AddRecord(Table, WebColors.Olive, 128, 128, 0);
	AddRecord(Table, WebColors.Olivedrab, 107, 142, 35);
	AddRecord(Table, WebColors.Orange, 255, 165, 0);
	AddRecord(Table, WebColors.OrangeRed, 255, 69, 0);
	AddRecord(Table, WebColors.Orchid, 218, 112, 214);
	AddRecord(Table, WebColors.PaleGoldenrod, 238, 232, 170);
	AddRecord(Table, WebColors.PaleGreen, 152, 251, 152);
	AddRecord(Table, WebColors.PaleTurquoise, 175, 238, 238);
	AddRecord(Table, WebColors.PaleVioletRed, 219, 112, 147);
	AddRecord(Table, WebColors.PapayaWhip, 255, 239, 213);
	AddRecord(Table, WebColors.PeachPuff, 255, 218, 185);
	AddRecord(Table, WebColors.Peru, 205, 133, 63);
	AddRecord(Table, WebColors.Pink, 255, 192, 203);
	AddRecord(Table, WebColors.Plum, 221, 160, 221);
	AddRecord(Table, WebColors.PowderBlue, 176, 224, 230);
	AddRecord(Table, WebColors.Purple, 160, 32, 240);
	AddRecord(Table, WebColors.Red, 255, 0, 0);
	AddRecord(Table, WebColors.RosyBrown, 188, 143, 143);
	AddRecord(Table, WebColors.RoyalBlue, 65, 105, 225);
	AddRecord(Table, WebColors.SaddleBrown, 139, 69, 19);
	AddRecord(Table, WebColors.Salmon, 250, 128, 114);
	AddRecord(Table, WebColors.SandyBrown, 244, 164, 96);
	AddRecord(Table, WebColors.Seagreen, 46, 139, 87);
	AddRecord(Table, WebColors.SeaShell, 255, 245, 238);
	AddRecord(Table, WebColors.Sienna, 160, 82, 45);
	AddRecord(Table, WebColors.Silver, 192, 192, 192);
	AddRecord(Table, WebColors.SkyBlue, 135, 206, 235);
	AddRecord(Table, WebColors.SlateBlue, 106, 90, 205);
	AddRecord(Table, WebColors.SlateGray, 112, 128, 144);
	AddRecord(Table, WebColors.Snow, 255, 250, 250);
	AddRecord(Table, WebColors.SpringGreen, 0, 255, 127);
	AddRecord(Table, WebColors.SteelBlue, 70, 130, 180);
	AddRecord(Table, WebColors.Tan, 210, 180, 140);
	AddRecord(Table, WebColors.Teal, 0, 128, 128);
	AddRecord(Table, WebColors.Thistle, 216, 191, 216);
	AddRecord(Table, WebColors.Tomato, 255, 99, 71);
	AddRecord(Table, WebColors.Turquoise, 64, 224, 208);
	AddRecord(Table, WebColors.Violet, 238, 130, 238);
	AddRecord(Table, WebColors.VioletRed, 208, 32, 144);
	AddRecord(Table, WebColors.Wheat, 245, 222, 179);
	AddRecord(Table, WebColors.White, 255, 255, 255);
	AddRecord(Table, WebColors.WhiteSmoke, 245, 245, 245);
	AddRecord(Table, WebColors.Yellow, 255, 255, 0);
	AddRecord(Table, WebColors.YellowGreen, 154, 205, 50);
	
	Table.Indexes.Add("WebColor_");
	
	Return Table;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure AddRecord(Table, Value1, Value2, Value3, Value4)
	
	TMCommonUse.AddRecord(Table, Value1, Value2, Value3, Value4);
	
EndProcedure

Function ConfigurationLanguageCode()
	If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.Russian Then
		Language = "Russian";
	Else
		Language = "English";
	EndIf;
	LanguageCode = Metadata.Languages[Language].LanguageCode;
	Return LanguageCode;
EndFunction

#EndRegion
