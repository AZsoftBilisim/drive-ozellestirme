///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables
&AtClient
Var SearchDirectionValue;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Users.IsExternalUserSession() Then
		Return;
	EndIf;
		
	SearchState = FullTextSearchServer.FullTextSearchStatus();
	LoadSettingsAndSearchHistory();
	
	If Not IsBlankString(Parameters.PassedSearchString) Then
		SearchString = Parameters.PassedSearchString;
		OnExecuteSearchAtServer(SearchString);
	Else	
		UpdateForm(New Array);
	EndIf;
	
	UpdateSearchAreaPresentation();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	If UsersClient.IsExternalUserSession() Then 
		Cancel = True;
		Raise(NStr("vi = 'Không đủ quyền để thực hiện tìm kiếm.';
					|ru = 'Недостаточно прав для выполнения поиска.';
					|en = 'Insufficient rights to search.'; fa = 'Insufficient rights to search.';
					|it = 'Недостаточно прав для выполнения поиска.';
					|pl = 'Insufficient rights to search.';
					|tr = 'Arama yapmak için yetersiz yetki.'"), ErrorCategory.AccessViolation);
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchStringChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
#If WebClient Then
	If Items.SearchString.ChoiceList.Count() = 1 Then
		ValueSelected = Item.EditText;
	EndIf;
#EndIf
	
	SearchString = ValueSelected;
	OnExecuteSearch("FirstPart");
	
EndProcedure

&AtClient
Procedure SearchAreasPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("SearchAreas",   SearchAreas);
	OpeningParameters.Insert("SearchInSections", SearchInSections);
	
	Notification = New CallbackDescription("AfterGetSearchAreaSettings", ThisObject);
	OpenForm("DataProcessor.FullTextSearchInData.Form.SearchAreaChoice",
		OpeningParameters,,,,, Notification);
	
EndProcedure

&AtClient
Procedure HTMLTextOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	
	HTMLRef = EventData.Anchor;
	If HTMLRef = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("AfterOpenURL", ThisObject);
	FileSystemClient.OpenURL(HTMLRef.href, Notification);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteSearch(Command)
	
	OnExecuteSearch("FirstPart");
	
EndProcedure

&AtClient
Procedure PreviousPages(Command)
	
	OnExecuteSearch("PreviousPart");
	
EndProcedure

&AtClient
Procedure NextPages(Command)
	
	OnExecuteSearch("NextPart");
	
EndProcedure

#EndRegion

#Region Private

#Region PrivateEventHandlers

&AtClient
Procedure AfterGetSearchAreaSettings(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		OnSetSearchArea(Result);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnSetSearchArea(SearchAreaSettings)
	
	SaveSearchSettings(SearchAreaSettings.SearchInSections, SearchAreaSettings.SearchAreas);
	SearchAreas = SearchAreaSettings.SearchAreas;
	SearchInSections = SearchAreaSettings.SearchInSections;
	UpdateSearchAreaPresentation();
	
EndProcedure

&AtClient
Procedure OnExecuteSearch(Val Var_SearchDirection)
	
	If IsBlankString(SearchString) Then
		ShowMessageBox(, NStr("vi = 'Hãy nhập những gì bạn cần tìm.';
								|ru = 'Введите, что нужно найти.';
								|en = 'Please enter text to search for.'; fa = 'Please enter text to search for.';
								|it = 'Inserire ciò che bisogna trovare.';
								|pl = 'Wpisz, co chcesz znaleźć.';
								|tr = 'Bulunması gerekeni girin'"));
		Return;
	EndIf;
	
	If CommonInternalClient.IsURL(SearchString) Then
		FileSystemClient.OpenURL(SearchString);
		SearchString = "";
		Return;
	EndIf;
	
	SearchDirectionValue = Var_SearchDirection;
	AttachIdleHandler("OnExecuteSearchCompletion", 0.1, True);
	
EndProcedure

&AtClient
Procedure OnExecuteSearchCompletion()
	
	OnExecuteSearchAtServer(SearchString, SearchDirectionValue);
	
EndProcedure

&AtServer
Procedure OnExecuteSearchAtServer(Val SearchString, Val Var_SearchDirection = "FirstPart")
	
	SaveSearchStringToHistory(SearchString);
	
	SearchParameters = FullTextSearchServer.SearchParameters();
	SearchParameters.CurrentPosition = CurrentPosition;
	SearchParameters.SearchInSections = SearchInSections;
	SearchParameters.SearchAreas = SearchAreas;
	SearchParameters.SearchString = SearchString;
	SearchParameters.SearchDirection = Var_SearchDirection;
	
	SearchResult = FullTextSearchServer.ExecuteFullTextSearch(SearchParameters);
	CurrentPosition = SearchResult.CurrentPosition;
	Count = SearchResult.Count;
	TotalCount = SearchResult.TotalCount;
	ErrorCode = SearchResult.ErrorCode;
	ErrorDescription = SearchResult.ErrorDescription;
	
	SearchState = FullTextSearchServer.FullTextSearchStatus();
	UpdateForm(SearchResult.SearchResults);

EndProcedure

&AtClient
Procedure AfterOpenURL(ApplicationStarted, Context) Export
	
	If Not ApplicationStarted Then 
		ShowMessageBox(, NStr("vi = 'Không xem xét việc mở đối tượng kiểu này';
								|ru = 'Открытие объектов данного типа не предусмотрено';
								|en = 'Cannot open objects of this type'; fa = 'Cannot open objects of this type';
								|it = 'L''apertura di oggetti di questo tipo non è supportata';
								|pl = 'Otwarcie obiektów tego typu nie jest przewidziano';
								|tr = 'Bu tür nesneler açılmaz'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region Presentations

&AtServer
Procedure UpdateForm(SearchResults)
	
	If Count = 0 Then
		Items.NextPages.Enabled  = False;
		Items.PreviousPages.Enabled = False;
	Else
		Items.NextPages.Enabled  = (TotalCount - CurrentPosition) > Count;
		Items.PreviousPages.Enabled = (CurrentPosition > 0);
	EndIf;
	
	If Count <> 0 Then
		FoundItemsInformationPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hiển thị %1 - %2 từ %3';
				|ru = 'Показаны %1 - %2 из %3';
				|en = 'Results %1–%2 out of %3'; fa = 'Results %1–%2 out of %3';
				|it = 'Mostrati %1 - %2 su %3';
				|pl = 'Pokazane %1 - %2 z %3';
				|tr = 'Gösterilen %1 - %2''den %3'"),
			Format(CurrentPosition + 1, "NZ=0; NG="),
			Format(CurrentPosition + Count, "NZ=0; NG="),
			Format(TotalCount, "NZ=0; NG="));
	Else		
		FoundItemsInformationPresentation = "";
	EndIf;
	
	If IsBlankString(ErrorCode) Then 
		SearchResultsPresentation = NewHTMLResultPage(SearchResults);
	Else 
		SearchResultsPresentation = NewHTMLErrorPage();
	EndIf;
	
	If SearchState = "SearchAllowed" Then 
		SearchStatePresentation = "";
	ElsIf SearchState = "IndexUpdateInProgress"
		Or SearchState = "IndexMergeInProgress"
		Or SearchState = "IndexUpdateRequired" Then 
		
		SearchStatePresentation = NStr("vi = 'Kết quả tìm kiếm có thể không chính xác, hãy thử lại sau.';
										|ru = 'Результаты поиска могут быть неточными, повторите поиск позднее.';
										|en = 'Search results might be inaccurate. Try the search later.'; fa = 'نتایج جستجو ممکن است نادقیق باشند. بعداً جستجو کنید.';
										|it = 'I risultati della ricerca potrebbero essere imprecisi, ripetere la ricerca in un secondo momento.';
										|pl = 'Wyniki wyszukiwania mogą być niedokładne, powtórz wyszukiwanie później.';
										|tr = 'Arama sonuçları yanlış olabilir, daha sonra aramayı tekrarlayın.'");
	ElsIf SearchState = "SearchSettingsError" Then 
		
		// For non-administrators.
		SearchStatePresentation = NStr("vi = 'Chưa tùy chỉnh tìm kiếm toàn văn, hãy liên hệ với người quản trị.';
										|ru = 'Полнотекстовый поиск не настроен, обратитесь к администратору.';
										|en = 'Full-text search is not set up. Contact your administrator.'; fa = 'Full-text search is not set up. Contact your administrator.';
										|it = 'Ricerca full-text non impostata, rivolgetevi all''amministratore.';
										|pl = 'Wyszukiwanie pełnotekstowe nie jest ustawione, zwróć się do administratora.';
										|tr = 'Tam metin araması yapılandırılmamıştır, yöneticinize başvurun.'");
		
	ElsIf SearchState = "SearchProhibited" Then 
		SearchStatePresentation = NStr("vi = 'Đã tắt bỏ tính năng tìm kiếm toàn văn.';
										|ru = 'Полнотекстовый поиск отключен.';
										|en = 'Full-text search is disabled.'; fa = 'Full-text search is disabled.';
										|it = 'Ricerca full-text disabilitata.';
										|pl = 'Wyszukiwanie pełnotekstowe zostało wyłączone.';
										|tr = 'Tam metin araması devre dışı.'");
	EndIf;
	
	Items.SearchState.Visible = (SearchState <> "SearchAllowed");

EndProcedure

&AtServer
Procedure UpdateSearchAreaPresentation()
	
	SearchAreasSpecified = SearchAreas.Count() > 0;
	
	If Not SearchInSections Or Not SearchAreasSpecified Then
		SearchAreasPresentation = NStr("vi = 'Mọi nơi';
										|ru = 'Везде';
										|en = 'Everywhere'; fa = 'همه جا';
										|it = 'Ovunque';
										|pl = 'Wszędzie';
										|tr = 'Her yerde'");
		Return;
	EndIf;
	
	If SearchAreas.Count() < 5 Then
		SearchAreasPresentation = "";
		For Each Area In SearchAreas Do
			MetadataObject = Common.MetadataObjectByID(Area.Value);
			SearchAreasPresentation = SearchAreasPresentation + Common.ListPresentation(MetadataObject) + ", ";
		EndDo;
		SearchAreasPresentation = Left(SearchAreasPresentation, StrLen(SearchAreasPresentation) - 2);
	Else	
		SearchAreasPresentation = NStr("vi = 'Trong các phân hệ đã chọn';
										|ru = 'В выбранных разделах';
										|en = 'In selected sections'; fa = 'In selected sections';
										|it = 'Nelle sezioni selezionate';
										|pl = 'W wybranych rozdziałach';
										|tr = 'Seçilmiş bölümlerde'");
	EndIf;
	
EndProcedure

// Parameters:
//  SearchResults - Array of Structure:
//    * Ref - String
//    * HTMLDetails - String
//    * Presentation - String
//
// Returns:
//  String
//
&AtServer
Function NewHTMLResultPage(SearchResults)
	
	LayoutTemplate = 
		"<html>
		|<head>
		|  <meta http-equiv=""Content-Type"" content=""text/html; charset=UTF-8"">
		|  <style type=""text/css"">
		|    html {
		|      overflow: auto;
		|    }
		|    body {
		|      margin: 10px;
		|      font-family: Arial, sans-serif;
		|      font-size: 10pt;
		|      overflow: auto;
		|      position: absolute;
		|      top: 0;
		|      left: 0;
		|      bottom: 0;
		|      right: 0;
		|    }
		|    div.main {
		|      overflow: auto;
		|      height: 100%;
		|    }
		|    div.presentation {
		|      font-size: 11pt;
		|    }
		|    div.textPortion {
		|      padding-bottom: 16px;
		|    }
		|    span.bold {
		|      font-weight: bold;
		|    }
		|    ol li {
		|      color: #B3B3B3;
		|    }
		|    ol li div {
		|      color: #333333;
		|    }
		|    a {
		|      text-decoration: none;
		|      color: #0066CC;
		|    }
		|    a:hover {
		|      text-decoration: underline;
		|    }
		|    .gray {
		|      color: #B3B3B3;
		|    }
		|  </style>
		|</head>
		|<body>
		|  <div class=""main"">
		|    <ol start=""%CurrentPosition%"">
		|%Rows%
		|    </ol>
		|  </div>
		|</body>
		|</html>";
	
	StringPattern = 
		"      <li>
		|        <div class=""presentation""><a href=""%Ref%"">%Presentation%</a></div>
		|        %HTMLDetails%
		|      </li>";
	
	InactiveStringPattern = 
		"      <li>
		|        <div class=""presentation""><a href=""#"" class=""gray"">%Presentation%</a></div>
		|        %HTMLDetails%
		|      </li>";
	
	Rows = "";
	
	For Each SearchResultString In SearchResults Do 
		
		Ref        = SearchResultString.Ref;
		Presentation = SearchResultString.Presentation;
		HTMLDetails  = SearchResultString.HTMLDetails;
		
		If Ref = "#" Then 
			String = InactiveStringPattern;
		Else 
			String = StrReplace(StringPattern, "%Ref%", Ref);
		EndIf;
		
		String = StrReplace(String, "%Presentation%", Presentation);
		String = StrReplace(String, "%HTMLDetails%",  HTMLDetails);
		
		Rows = Rows + String;
		
	EndDo;
	
	HTMLPage = StrReplace(LayoutTemplate, "%Rows%", Rows);
	HTMLPage = StrReplace(HTMLPage  , "%CurrentPosition%", CurrentPosition + 1);
	
	Return HTMLPage;
	
EndFunction

&AtServer
Function NewHTMLErrorPage()
	
	LayoutTemplate = 
		"<html>
		|<head>
		|  <meta http-equiv=""Content-Type"" content=""text/html; charset=UTF-8"">
		|  <style type=""text/css"">
		|    html { 
		|      overflow:auto;
		|    }
		|    body {
		|      margin: 10px;
		|      font-family: Arial, sans-serif;
		|      font-size: 10pt;
		|      overflow: auto;
		|      position: absolute;
		|      top: 0;
		|      left: 0;
		|      bottom: 0;
		|      right: 0;
		|    }
		|    div.main {
		|      overflow: auto;
		|      height: 100%;
		|    }
		|    div.error {
		|      font-size: 12pt;
		|    }
		|    div.presentation {
		|      font-size: 11pt;
		|    }
		|    h3 {
		|      color: #009646
		|    }
		|    li {
		|      padding-bottom: 16px;
		|    }
		|    a {
		|      text-decoration: none;
		|      color: #0066CC;
		|    }
		|    a:hover {
		|      text-decoration: underline;
		|    }
		|  </style>
		|</head>
		|<body>
		|  <div class=""main"">
		|    <div class=""error"">%1</div>
		|    <p>%2</p>
		|  </div>
		|</body>
		|</html>";
	
	HTMLRecommendations = 
		NStr("vi = '<h3>Khuyến cáo:</h3>
			|<ul>
			|  %1
			|  %2
			|  <li>
			|    <b>Hãy thử tìm kiếm từ đầu.</b><br>
			|    Sử dụng dấu sao (*) để kết thúc.<br>
			|    Ví dụ, tìm kiếm xây* sẽ tìm kiếm tất cả chứng từ có chứa các từ bắt đầu bằng từ xây - 
			|    Nhật ký ""Xây dựng và sửa chữa"", ""Công ty TNHH Tổ hợp xây dựng"" ...
			|  </li>
			|  <li>
			|    <b>Hãy sử dụng tìm kiếm không chính xác.</b><br>
			|    Sử dụng dấu thăng (#).<br>
			|    Ví dụ, Romashka#2 sẽ tìm thấy tất cả chứng từ có chứa các từ khác với 
			|    Romashka một hoặc hai chữ cái.
			|  </li>
			|</ul>
			|<div class ""presentation""><a href=""%3"">Mô tả đầy đủ định dạng biểu thức tìm kiếm</a></div>';
			|ru = '<h3>Рекомендации:</h3>
			|<ul>
			|  %1
			|  %2
			|  <li>
			|    <b>Воспользуйтесь поиском по началу слова.</b><br>
			|    Используйте звездочку (*) в качестве окончания.<br>
			|    Например, поиск стро* найдет все документы, которые содержат слова, начинающиеся на стро - 
			|    Журнал ""Строительство и ремонт"", ""ООО СтройКомплект"" и.т.д.
			|  </li>
			|  <li>
			|    <b>Воспользуйтесь нечетким поиском.</b><br>
			|    Используйте решетку (#).<br>
			|    Например, Ромашка#2 найдет все документы, содержащие такие слова, которые отличаются от слова 
			|    Ромашка на одну или две буквы.
			|  </li>
			|</ul>
			|<div class ""presentation""><a href=""%3"">Полное описание формата поисковых выражений</a></div>';
			|en = '<h3>Recommended:</h3>
			|<ul>
			|  %1
			|  %2
			|  <li>
			|    <b>Search by beginning of a word.</b><br>
			|    Use asterisk (*) as a wildcat symbol.<br>
			|    For example, a search for cons* will find all documents containing words that start with the same letters:
			|    Construction and Repair, Construction Works Ltd, and so on.
			|  </li>
			|  <li>
			|    <b>Fuzzy search.</b><br>
			|    For fuzzy search, use the number sign (#).<br>
			|    For example, a search for Child#3 will find all documents containing words that differ from the word 
			|    Child by one, two, or three letters.
			|   </li>
			|</ul>
			|<div class ""presentation""><a href=""%3"">Searching with regular expressions</a></div>'; fa = '<h3>Recommended:</h3>
			|<ul>
			|  %1
			|  %2
			|  <li>
			|    <b>Search by beginning of a word.</b><br>
			|    Use asterisk (*) as a wildcat symbol.<br>
			|    For example, a search for cons* will find all documents containing words that start with the same letters:
			|    Construction and Repair, Construction Works Ltd, and so on.
			|  </li>
			|  <li>
			|    <b>Fuzzy search.</b><br>
			|    For fuzzy search, use the number sign (#).<br>
			|    For example, a search for Child#3 will find all documents containing words that differ from the word 
			|    Child by one, two, or three letters.
			|   </li>
			|</ul>
			|<div class ""presentation""><a href=""%3"">Searching with regular expressions</a></div>';
			|it = '<h3>Рекомендации:</h3>
			|<ul>
			|  %1
			|  %2
			|  <li>
			|    <b>Воспользуйтесь поиском по началу слова.</b><br>
			|    Используйте звездочку (*) в качестве окончания.<br>
			|    Например, поиск стро* найдет все документы, которые содержат слова, начинающиеся на стро - 
			|    Журнал ""Строительство и ремонт"", ""ООО СтройКомплект"" и.т.д.
			|  </li>
			|  <li>
			|    <b>Воспользуйтесь нечетким поиском.</b><br>
			|    Используйте решетку (#).<br>
			|    Например, Ромашка#2 найдет все документы, содержащие такие слова, которые отличаются от слова 
			|    Ромашка на одну или две буквы.
			|  </li>
			|</ul>
			|<div class ""presentation""><a href=""%3"">Полное описание формата поисковых выражений</a></div>';
			|pl = '<h3>Recommended:</h3>
			|<ul>
			|  %1
			|  %2
			|  <li>
			|    <b>Search by beginning of a word.</b><br>
			|    Use asterisk (*) as a wildcat symbol.<br>
			|    For example, a search for cons* will find all documents containing words that start with the same letters:
			|    Construction and Repair, Construction Works Ltd, and so on.
			|  </li>
			|  <li>
			|    <b>Fuzzy search.</b><br>
			|    For fuzzy search, use the number sign (#).<br>
			|    For example, a search for Child#3 will find all documents containing words that differ from the word 
			|    Child by one, two, or three letters.
			|   </li>
			|</ul>
			|<div class ""presentation""><a href=""%3"">Searching with regular expressions</a></div>';
			|tr = '<h3>Öneriler:</h3>
			|<ul>
			|  %1
			|  %2
			| <li>
			|    <b>Kelimenin başına göre arayın.</b><br>
			|   Kelimenin sonu olarak (*) kullanın.<br>
			|  Örneğin, sat* olarak yapılan arama, sat- ile başlayan tüm kelimeleri bulacaktır - 
			|   ""İnşaat ve onarım"" dergisi, ""StroyKomplekt Ltd."" vs.
			|</li>
			|  <li>
			|    <b>Bulanık aramayı kullanın.</b><br>
			|    (#) kullanın.<br>
			|   Örneğin, Papatya#2 
			| Papatya kelimesinden bir veya iki harf farkı olan tüm kelimeleri bulur.
			|  </li>
			|</ul>
			|<div class ""presentation""><a href=""%3"">Arama ifade biçiminin tam açıklaması</a></div>'");
	
	SearchAreasSpecified = SearchAreas.Count() > 0;
	
	SearchAreaRecommendationHTML = "";
	QueryTextRecommendationHTML = "";
	
	If ErrorCode = "FoundNothing" Then 
		
		If SearchInSections And SearchAreasSpecified Then 
		
			SearchAreaRecommendationHTML = 
				NStr("vi = '<li><b>Làm rõ vùng tìm kiếm.</b><br>
					|Thử chọn nhiều vùng tìm kiếm hơn hoặc tất cả phân hệ.</li>';
					|ru = '<li><b>Уточните область поиска.</b><br>
					|Попробуйте выбрать больше областей поиска или все разделы.</li>';
					|en = '<li><b>Refine the search.</b><br>
					|Try to select other locations.</li>'; fa = '<li><b>Refine the search.</b><br>
					|Try to select other locations.</li>';
					|it = '<li><b>Уточните область поиска.</b><br>
					|Попробуйте выбрать больше областей поиска или все разделы.</li>';
					|pl = '<li><b>Refine the search.</b><br>
					|Try to select other locations.</li>';
					|tr = '<li><b>Arama alanını netleştirin.</b><br>
					|Daha fazla arama alanı veya tüm bölümleri seçmeyi deneyin.</li>'");
		EndIf;
		
		QueryTextRecommendationHTML =
			NStr("vi = '<li><b>Hãy đơn giản hóa yêu cầu bằng cách bỏ bớt từ bất kỳ.</b></li>';
				|ru = '<li><b>Упростите запрос, исключив из него какое-либо слово.</b></li>';
				|en = '<li><b>Try searching for fewer words.</b></li>'; fa = '<li><b>Try searching for fewer words.</b></li>';
				|it = '<li><b>Упростите запрос, исключив из него какое-либо слово.</b></li>';
				|pl = '<li><b>Try searching for fewer words.</b></li>';
				|tr = '<li><b>Herhangi bir kelimeyi hariç tutarak sorguyu basitleştirin.</b></li>'");
		
	ElsIf ErrorCode = "TooManyResults" Then
		
		If Not SearchInSections Or Not SearchAreasSpecified Then 
			
			SearchAreaRecommendationHTML = 
			NStr("vi = '<li><b>Làm rõ vùng tìm kiếm.</b><br>
				|Thử chọn vùng tìm kiếm bằng cách chỉ định phân hệ hoặc danh sách chính xác.</li>';
				|ru = '<li><b>Уточните область поиска.</b><br>
				|Попробуйте выбрать область поиска, задав точный раздел или список.</li>';
				|en = '<li><b>Refine the search.</b><br>
				|Try to select a location or list.</li>'; fa = '<li><b>Refine the search.</b><br>
				|Try to select a location or list.</li>';
				|it = '<li><b>Уточните область поиска.</b><br>
				|Попробуйте выбрать область поиска, задав точный раздел или список.</li>';
				|pl = '<li><b>Refine the search.</b><br>
				|Try to select a location or list.</li>';
				|tr = '<li><b>Arama alanını netleştirin.</b><br>
				|Tam bir bölüm veya liste belirterek bir arama alanı seçmeyi deneyin.</li>'");
		EndIf;
		
	EndIf;
	
	HTMLRecommendations = StringFunctionsClientServer.SubstituteParametersToString(HTMLRecommendations, 
		SearchAreaRecommendationHTML, QueryTextRecommendationHTML,
		"v8help://1cv8/QueryLanguageFullTextSearchInData");
	
	Return StringFunctionsClientServer.SubstituteParametersToString(LayoutTemplate, ErrorDescription, HTMLRecommendations);
	
EndFunction

#EndRegion

#Region SearchSetupHistory

&AtServer
Procedure LoadSettingsAndSearchHistory()
	
	SearchHistory = Common.CommonSettingsStorageLoad("FullTextSearchFullTextSearchStrings", "", New Array);
	Items.SearchString.ChoiceList.LoadValues(SearchHistory);
	
	SavedSearchSettings = Common.CommonSettingsStorageLoad("FullTextSearchSettings", "", SearchSettings1());
	SearchInSections = SavedSearchSettings.SearchInSections;
	SearchAreas   = SavedSearchSettings.SearchAreas;
	
EndProcedure

&AtServer
Procedure SaveSearchStringToHistory(SearchString)
	
	SearchHistory = Common.CommonSettingsStorageLoad("FullTextSearchFullTextSearchStrings", "", New Array);
	SavedString = SearchHistory.Find(SearchString);
	If SavedString <> Undefined Then
		SearchHistory.Delete(SavedString);
	EndIf;
	
	SearchHistory.Insert(0, SearchString);
	RowsCount = SearchHistory.Count();
	If RowsCount > 20 Then
		SearchHistory.Delete(RowsCount - 1);
	EndIf;
	
	Common.CommonSettingsStorageSave("FullTextSearchFullTextSearchStrings", "", SearchHistory);
	Items.SearchString.ChoiceList.LoadValues(SearchHistory);
	
EndProcedure

&AtServerNoContext
Procedure SaveSearchSettings(SearchInSections, SearchAreas)
	
	Settings = SearchSettings1();
	Settings.SearchInSections = SearchInSections;
	Settings.SearchAreas = SearchAreas;
	
	Common.CommonSettingsStorageSave("FullTextSearchSettings", "", Settings);
	
EndProcedure

&AtServerNoContext
Function SearchSettings1()
	
	Settings = New Structure;
	Settings.Insert("SearchInSections", False);
	Settings.Insert("SearchAreas",   New ValueList);
	Return Settings;
	
EndFunction

#EndRegion

#EndRegion
