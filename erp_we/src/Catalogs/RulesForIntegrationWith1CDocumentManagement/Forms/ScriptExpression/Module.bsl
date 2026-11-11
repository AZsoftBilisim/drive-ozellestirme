#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ObjectTypeDM", ObjectTypeDM);
	Parameters.Property("ObjectTypeIS", ObjectTypeIS);
	Parameters.Property("DocumentKindDM", DocumentKindDM);
	Parameters.Property("ComputedExpression", ComputedExpression);
	Parameters.Property("TypeOfExpression", TypeOfExpression);
	
	ArrayInstructions = New Array;
	
	ArrayInstructions.Add(
		"<html>
		|<style type=""text/css"">
		|	body {
		|		overflow:    auto;
		|		margin-top:  12px;
		|		margin-left: 20px;
		|		font-family: MS Shell Dlg, Microsoft Sans Serif, sans-serif;
		|		font-size:   8pt;}
		|	table {
		|		width:       450px;
		|		font-family: MS Shell Dlg, Microsoft Sans Serif, sans-serif;
		|		font-size:   8pt;}
		|	td {vertical-align: top;}
		|	p {
		|		margin-top: 7px;}
		|</style>
		|<body>");
	
	If TypeOfExpression = "ExportRule" Or TypeOfExpression = "LoadingRule" Then
		
		Title = NStr("vi = 'Biểu thức bằng ngôn ngữ hệ thống';
					|ru = 'Выражение на встроенном языке';
					|en = 'Expression in the script '; fa = 'عبارت در اسکریپت';
					|it = 'Espressione nel linguaggio integrato';
					|pl = 'Wyrażenie w języku wbudowanym';
					|tr = 'Gömülü dilde ifade'");
		
		ArrayInstructions.Add("<p>");
		ArrayInstructions.Add(
			StrTemplate(
				NStr("vi = 'Kết quả tính toán biểu thức bằng ngôn ngữ hệ thống 1C:Enterprise
					|cần gán thuộc tính %1 cho biến %2.';
					|ru = 'Результат вычисления выражения на встроенном языке 1С:Предприятия
					|должен присваиваться свойству %1 переменной %2.';
					|en = 'Result of the expression calculation in 1C:Enterprise
					|language should be assigned to the %1 property of the %2 variable.'; fa = 'Result of the expression calculation in 1C:Enterprise
					|language should be assigned to the %1 property of the %2 variable.';
					|it = 'Il risultato del calcolo dell''espressione nel linguaggio integrato di 1C:Enterprise
					|deve essere assegnato alla proprietà %1 modificata da %2.';
					|pl = 'Wynik obliczenia w języku wbudowanym 1С:Enterprise
					|powinien być przypisywany według właściwości %1 zmiennej %2.';
					|tr = '1C:Enterprise
					|yerleşik dilindeki ifadenin hesaplanmasının sonucu, değişkenin özelliğine %1tanımlanmalıdır %2.'"),
				"<b>Result</b>",
				"<b>Parameters</b>"));
		ArrayInstructions.Add(" ");
			
		If Parameters.ThisIsTable Then
			ArrayInstructions.Add(
				StrTemplate(
					NStr("vi = 'Để điền bảng, kết quả cần có kiểu %1 với các cột:';
						|ru = 'Для заполнения таблицы результат должен иметь тип %1 с колонками:';
						|en = 'To fill in the table, the result must have the %1 type with the columns:'; fa = 'To fill in the table, the result must have the %1 type with the columns:';
						|it = 'Per la compilazione della tabella, il risultato deve avere tipo %1 con le colonne:';
						|pl = 'W celu wypełnienia tabeli wynik powinien mieć typ %1 z kolumnami:';
						|tr = 'Tabloyu doldurmak için sonucun sütun türünde %1 olması gerekir:'"),
				"<b>ValueTable</b>"));
			ArrayInstructions.Add("</p><table>");
			
			If TypeOfExpression = "ExportRule" Then
				MatchingXDTOProperties = Catalogs.RulesForIntegrationWith1CDocumentManagement.
					MatchingXDTPropertiesAndObjectFormDetailsTo(ObjectTypeDM);
				TableName = StrReplace(Parameters.AttributeNameObjectDM, ".rows", "");
				For Each Item In MatchingXDTOProperties[TableName].rows[1] Do
					ArrayInstructions.Add("<tr><td>");
					ArrayInstructions.Add(Item.Value);
					ArrayInstructions.Add("</td></tr>");
				EndDo;
			Else
				ObjectMetadata = Metadata.FindByFullName(ObjectTypeIS);
				For Each Item In ObjectMetadata.TabularSections[Parameters.AttributeNameObjectIS].Attributes Do
					ArrayInstructions.Add("<tr><td>");
					ArrayInstructions.Add(Item.Name);
					ArrayInstructions.Add("</td></tr>");
				EndDo;
			EndIf;
			
			ArrayInstructions.Add("</table>");
			
		ElsIf TypeOfExpression = "ExportRule" Then
			ArrayInstructions.Add(
				StrTemplate(
					NStr("vi = 'Để thiết lập giá trị tham chiếu trong 1C:Document Management
						|cho thuộc tính %1, cần gán dòng có tên của kiểu theo
						|mô tả của web-service, cho thuộc tính %2 - định danh tham chiếu
						|hoặc tên giá trị liệt kê. Thuộc tính %3 trong trường hợp này được gán
						|trình bày kết quả tự tạo.';
						|ru = 'Для установки ссылочного значения на стороне 1С:Документооборота
						|свойству %1 следует присвоить строку с названием типа согласно
						|описанию веб-сервиса, а свойству %2 - идентификатор ссылки
						|или имя значения перечисления. Свойству %3 в этом случае присваивается
						|пользовательское представление результата.';
						|en = 'To set the reference value on the 1C:Document Management side, 
						|the %1 property must be assigned a string with the type name according to
						| the description of the web service, and the %2 property must be assigned the reference ID
						| or the name of the enumeration value. In this case, the %3 property is assigned
						| a custom representation of the result.'; fa = 'To set the reference value on the 1C:Document Management side, 
						|the %1 property must be assigned a string with the type name according to
						| the description of the web service, and the %2 property must be assigned the reference ID
						| or the name of the enumeration value. In this case, the %3 property is assigned
						| a custom representation of the result.';
						|it = 'Per l''impostazione del valore di collegamento, nella riga di 1C:Document Management
						| alla proprietà %1 serve assegnare la riga con nome del tipo in base
						|alla descrizione del servizio web, mentre alla proprietà %2. l''ID del collegamento
						|o il nome del valore di enumerazione. Alla proprietà %3 in questo caso viene assegnata
						|la presentazione utente del risultato.';
						|pl = 'W celu ustawienia wartości odnośnikowej ze strony 1С:Document Management
						|dla właściwości %1 należy przydzielić wiersz z nazwą typu zgodnie
						|z opisem usługi webowej, a właściwości %2 - identyfikator 
						|lub nazwę wartości przeliczenia. Właściwości %3 w tym przypadku jest przydzielana
						|prezentacja wyniku użytkownika.';
						|tr = '1C:Document Management tarafında bir referans değeri ayarlamak için,
						|%1 özelliğine web servisinin açıklamasına göre
						|türün adını içeren bir satır ve bağlantının tanımlayıcısı olan %2 özelliğine
						| atanmalıdır. numaralandırma değerinin adı. Bu durumda %3 özelliği, sonucun
						|özel temsiline tanımlanmıştır.'"),
					"<b>ResultType</b>",
					"<b>ResultID</b>",
					"<b>Result</b>"));
			
		EndIf;
		
	ElsIf TypeOfExpression = "ApplicabilityConditionOnExport" Then
		
		Title = NStr("vi = 'Điều kiện áp dụng quy tắc';
					|ru = 'Условие применимости правила';
					|en = 'Rule applicability condition'; fa = 'Rule applicability condition';
					|it = 'Condizione di applicabilità della regola';
					|pl = 'Warunek przydatności reguły';
					|tr = 'Kural uygulanabilirlik koşulu'");
		
		ArrayInstructions.Add("<p>");
		ArrayInstructions.Add(
			StrTemplate(
				NStr("vi = 'Biểu thức bằng ngôn ngữ hệ thống 1C:Enterprise xác định
					|khả năng áp dụng quy tắc khi tạo đối tượng 1C:Document Management trên cơ sở
					|đối tượng của cấu hình này. Kết quả tính toán cần được gán cho thuộc tính
					|%1 biến %2. Giá trị %3 có nghĩa là áp dụng quy tắc,
					|%4 - không áp dụng. Biểu thức chỉ được kiểm tra đối với các quy tắc
					|phù hợp với giá trị của các mục tin chính.
					|%5 Giá trị mặc định: %3.';
					|ru = 'Выражение на встроенном языке 1С:Предприятия определяет
					|применимость правила при создании объекта 1С:Документооборота на основании
					|объекта этой конфигурации. Результат вычисления должен присваиваться свойству
					|%1 переменной %2. Значение %3 говорит о применимости правила,
					|%4 - о неприменимости. Выражение проверяется только для правил,
					|подходящих по значениям ключевых реквизитов.
					|%5Значение по умолчанию: %3.';
					|en = 'Expression in 1C:Enterprise language determines
					|the rule applicability when creating this configuration object based on a 
					|1C:Document Management object. The calculation result must be assigned to the 
					|%1 property of the %2 variable. The %3 value means that the rule is applicable,
					|%4 means the rule is inapplicable. The expression is checked only for the rules
					|that have required values of key attributes.
					|%5Default value: %3.'; fa = 'Expression in 1C:Enterprise language determines
					|the rule applicability when creating this configuration object based on a 
					|1C:Document Management object. The calculation result must be assigned to the 
					|%1 property of the %2 variable. The %3 value means that the rule is applicable,
					|%4 means the rule is inapplicable. The expression is checked only for the rules
					|that have required values of key attributes.
					|%5Default value: %3.';
					|it = 'Expression in 1C:Enterprise language determines
					|the rule applicability when creating this configuration object based on a 
					|1C:Document Management object. The calculation result must be assigned to the 
					|%1 property of the %2 variable. The %3 value means that the rule is applicable,
					|%4 means the rule is inapplicable. The expression is checked only for the rules
					|that have required values of key attributes.
					|%5Default value: %3.';
					|pl = 'Expression in 1C:Enterprise language determines
					|the rule applicability when creating this configuration object based on a 
					|1C:Document Management object. The calculation result must be assigned to the 
					|%1 property of the %2 variable. The %3 value means that the rule is applicable,
					|%4 means the rule is inapplicable. The expression is checked only for the rules
					|that have required values of key attributes.
					|%5Default value: %3.';
					|tr = '1C:Enterprise yerleşik dilindeki ifade, bir 1C:Document Management nesnesinin, bu yapılandırmanın
					|nesnesine dayalı olarak oluşturulması sırasında kuralın
					|uygulanabilirliğini belirler. Hesaplama sonucu, %2değişkeninin 
					|%1  özelliğine atanmalıdır. %3değeri kuralın uygulanabilir olduğunu,
					|%4 ise uygulanamaz olduğunu gösterir. İfade, yalnızca anahtar öznitelik değerlerine göre uygun olan 
					| kurallar için denetlenir.
					|%5Varsayılan değer: %3.'"),
				"<b>Result</b>",
				"<b>Parameters</b>",
				"<b>True</b>",
				"<b>False</b>",
				"</p><p>"));
		ArrayInstructions.Add("<p>");
		
	ElsIf TypeOfExpression = "ApplicabilityConditionOnImport" Then
		
		Title = NStr("vi = 'Điều kiện áp dụng quy tắc';
					|ru = 'Условие применимости правила';
					|en = 'Rule applicability condition'; fa = 'Rule applicability condition';
					|it = 'Condizione di applicabilità della regola';
					|pl = 'Warunek przydatności reguły';
					|tr = 'Kural uygulanabilirlik koşulu'");
		
		ArrayInstructions.Add("<p>");
		ArrayInstructions.Add(
			StrTemplate(
				NStr("vi = 'Biểu thức bằng ngôn ngữ hệ thống 1C:Enterprise xác định
					|khả năng áp dụng quy tắc khi tạo đối tượng 1C:Document Management trên cơ sở
					|đối tượng của cấu hình này. Kết quả tính toán cần được gán cho thuộc tính
					|%1 biến %2. Giá trị %3 có nghĩa là áp dụng quy tắc,
					|%4 - không áp dụng. Biểu thức chỉ được kiểm tra đối với các quy tắc
					|phù hợp với giá trị của các mục tin chính.
					|%5 Giá trị mặc định: %3.';
					|ru = 'Выражение на встроенном языке 1С:Предприятия определяет
					|применимость правила при создании объекта этой конфигурации на основании
					|объекта 1С:Документооборота. Результат вычисления должен присваиваться свойству
					|%1 переменной %2. Значение %3 говорит о применимости правила,
					|%4 - о неприменимости. Выражение проверяется только для правил,
					|подходящих по значениям ключевых реквизитов.
					|%5Значение по умолчанию: %3.';
					|en = 'Expression in 1C:Enterprise language determines
					|the rule applicability when creating a 1C:Document Management object based on
					|this configuration object. The calculation result must be assigned to the 
					|%1 property of the %2 variable. The %3 value means that the rule is applicable,
					|%4 means the rule is inapplicable. The expression is checked only for the rules
					|that have required values of key attributes.
					|%5Default value: %3.'; fa = 'Expression in 1C:Enterprise language determines
					|the rule applicability when creating a 1C:Document Management object based on
					|this configuration object. The calculation result must be assigned to the 
					|%1 property of the %2 variable. The %3 value means that the rule is applicable,
					|%4 means the rule is inapplicable. The expression is checked only for the rules
					|that have required values of key attributes.
					|%5Default value: %3.';
					|it = 'Expression in 1C:Enterprise language determines
					|the rule applicability when creating a 1C:Document Management object based on
					|this configuration object. The calculation result must be assigned to the 
					|%1 property of the %2 variable. The %3 value means that the rule is applicable,
					|%4 means the rule is inapplicable. The expression is checked only for the rules
					|that have required values of key attributes.
					|%5Default value: %3.';
					|pl = 'Expression in 1C:Enterprise language determines
					|the rule applicability when creating a 1C:Document Management object based on
					|this configuration object. The calculation result must be assigned to the 
					|%1 property of the %2 variable. The %3 value means that the rule is applicable,
					|%4 means the rule is inapplicable. The expression is checked only for the rules
					|that have required values of key attributes.
					|%5Default value: %3.';
					|tr = '1C:Enterprise yerleşik dilindeki ifade, bu yapılandırmanın bir nesnesinin,
					|1C:Document Management nesnesine dayalı olarak oluşturulması sırasında kuralın
					|uygulanabilirliğini belirler. Hesaplama sonucu,%2değişkeninin
					|%1  özelliğine atanmalıdır. %3değeri kuralın uygulanabilir olduğunu,
					|%4ise uygulanamaz olduğunu gösterir. İfade, yalnızca anahtar öznitelik değerlerine göre uygun olan 
					|kurallar için denetlenir.
					|%5Varsayılan değer: %3'"),
				"<b>Result</b>",
				"<b>Parameters</b>",
				"<b>True</b>",
				"<b>False</b>",
				"</p><p>"));
		ArrayInstructions.Add("<p>");
		
	EndIf;
	
	ArrayInstructions.Add("<p>");
	ArrayInstructions.Add(NStr("vi = 'Với đối tượng';
								|ru = 'К объекту';
								|en = 'To object'; fa = 'To object';
								|it = 'All''oggetto';
								|pl = 'Do obiektu';
								|tr = 'Nesneye'"));
	ArrayInstructions.Add(" ");
	
	If TypeOfExpression = "LoadingRule" Or TypeOfExpression = "ApplicabilityConditionOnImport" Then
		ArrayInstructions.Add(NStr("vi = '1C:Document Management';
									|ru = '1С:Документооборота';
									|en = '1C:Document Management'; fa = '1C:Document Management';
									|it = '1C:Document Management';
									|pl = '1C:Document Management';
									|tr = '1C:Document Management''in'"));
		
		FillParameters = Undefined;
		If DocumentKindDM <> Undefined Then
			FillParameters = New Structure;
			FillParameters.Insert("documentType", DocumentKindDM);
		EndIf;
		
		AttributeSet = Catalogs.RulesForIntegrationWith1CDocumentManagement.ObjectAttributesBefore(
			ObjectTypeDM,
			FillParameters);
	Else // This is the "Rules of loading" or "Conditionsapplicable to the custom loading".
		ArrayInstructions.Add(NStr("vi = 'của cấu hình này';
									|ru = 'этой конфигурации';
									|en = 'this configuration'; fa = 'this configuration';
									|it = 'di questa configurazione';
									|pl = 'tej konfiguracji';
									|tr = 'bu yapılandırmanın'"));
		AttributeSet = IntegrationWith1CDocumentManagementCore.ObjectAttributesIS(ObjectTypeIS, True);
	EndIf;
	
	ArrayInstructions.Add(" ");
	ArrayInstructions.Add(
		StrTemplate(
			NStr("vi = 'có thể liên kết thông qua thuộc tính %1 của biến %2.
				|Các mục tin của nguồn:';
				|ru = 'можно обращаться через свойство %1 переменной %2.
				|Реквизиты источника:';
				|en = 'you can access it using the %1 property of the %2 variable.
				|Source attributes:'; fa = 'you can access it using the %1 property of the %2 variable.
				|Source attributes:';
				|it = 'è possibile rivolgersi tramite proprietà %1 modificata da %2.
				|Attributo della fonte:';
				|pl = 'można zwrócić się przez właściwość %1 zmiennej %2.
				|Atrybuty źródła:';
				|tr = '%1değişkenin %2 özelliği aracılığıyla erişilebilir. 
				| Kaynak öznitelikleri:'"),
			"<b>Source</b>",
			"<b>Parameters</b>"));
	ArrayInstructions.Add("</p><table>");
	
	If (TypeOfExpression = "LoadingRule" Or TypeOfExpression = "ApplicabilityConditionOnImport") Then
		AttributeSet.Sort("AdditionalAttribute5, ThisIsTable, Name");
	Else
		AttributeSet.Sort("IsAdditionalAttributeIS, ThisIsTable, Name");
	EndIf;
	
	HeaderOfAdditionalBankingDetailsIsDisplayed = False;
	IDOfAdditionalBankingDetails = "00000000-0000-0000-0000-000000000000";
	
	For Each AttributeStructure In AttributeSet Do
		
		If ValueIsFilled(AttributeStructure.Table) Then
			Continue;
		EndIf;
		
		If (TypeOfExpression = "LoadingRule" Or TypeOfExpression = "ApplicabilityConditionOnImport") Then
			IsAddlAttribute = AttributeStructure.AdditionalAttribute5;
		Else
			IsAddlAttribute = AttributeStructure.IsAdditionalAttributeIS;
		EndIf;
		
		If IsAddlAttribute And Not HeaderOfAdditionalBankingDetailsIsDisplayed Then
			ArrayInstructions.Add("<tr><td>");
			ArrayInstructions.Add("<b>");
			ArrayInstructions.Add(NStr("vi = 'Mục tin bổ sung:';
										|ru = 'Дополнительные реквизиты:';
										|en = 'Additional attributes:'; fa = 'ویژگی‌های تکمیلی:';
										|it = 'Requisiti aggiuntivi:';
										|pl = 'Atrybuty dodatkowe:';
										|tr = 'Ek öznitelikler:'"));
			ArrayInstructions.Add("</b>");
			ArrayInstructions.Add("</tr></td>");
			HeaderOfAdditionalBankingDetailsIsDisplayed = True;
		EndIf;
		
		If AttributeStructure.ThisIsTable Then
			ArrayInstructions.Add("<tr><td>");
			ArrayInstructions.Add("<b>");
			ArrayInstructions.Add(StrTemplate(NStr("vi = 'Phần bảng %1';
													|ru = 'Табличная часть %1';
													|en = 'Table %1'; fa = 'Table %1';
													|it = 'Табличная часть %1';
													|pl = 'Część tabelaryczna %1';
													|tr = 'Tablo %1'"), AttributeStructure.Name));
			ArrayInstructions.Add("</b></td>");
			
			If AttributeStructure.Presentation <> AttributeStructure.Name Then
				ArrayInstructions.Add("<td><b>");
				ArrayInstructions.Add(AttributeStructure.Presentation);
				ArrayInstructions.Add("</b></td>");
			EndIf;
			ArrayInstructions.Add("</tr>");
			
			TableAttributes = AttributeSet.FindRows(New Structure("Table", AttributeStructure.Name));
			For Each TableAttribute In TableAttributes Do
				ArrayInstructions.Add("<tr>");
				
				PrintAttributeNameBEFORE(ArrayInstructions, TableAttribute, TableAttribute.Name);
				
				If TableAttribute.Presentation <> TableAttribute.Name Then
					ArrayInstructions.Add("<td>");
					ArrayInstructions.Add(TableAttribute.Presentation);
					ArrayInstructions.Add("</td>");
				EndIf;
				
				ArrayInstructions.Add("</tr>");
			EndDo;
			Continue;
		EndIf;
		
		If IsAddlAttribute Then
			If (TypeOfExpression = "LoadingRule" Or TypeOfExpression = "ApplicabilityConditionOnImport") Then
				IDOfAdditionalBankingDetails = AttributeStructure.AdditionalAttribute5ID;
				AttributeName = StrTemplate("<a href=""#DMAdditionalProperty"">ID: ""%1""</a>", IDOfAdditionalBankingDetails);
			Else
				IDOfAdditionalBankingDetails = Common.ObjectAttributeValue(
					AttributeStructure.AdditionalAttributeIS,
					"IDForFormulas");
				AttributeName = StrTemplate("ID: ""%1""<br>IDForFormulas: ""%2""</br>",
					AttributeStructure.AdditionalAttributeIS.UUID(),
					IDOfAdditionalBankingDetails);
			EndIf;
		Else
			AttributeName = AttributeStructure.Name;
		EndIf;
		
		ArrayInstructions.Add("<tr>");
		
		PrintAttributeNameBEFORE(ArrayInstructions, AttributeStructure, AttributeName);
		
		If AttributeStructure.Presentation <> AttributeName Then
			ArrayInstructions.Add("<td>");
			ArrayInstructions.Add(AttributeStructure.Presentation);
			ArrayInstructions.Add("</td>");
		EndIf;
		
		ArrayInstructions.Add("</tr>");
		
	EndDo;
	
	ArrayInstructions.Add("</table>");
	
	If HeaderOfAdditionalBankingDetailsIsDisplayed Then
		ArrayInstructions.Add("<p>");
		AddCollapsibleGroup(ArrayInstructions, True);
		ArrayInstructions.Add("<summary><u>");
		ArrayInstructions.Add(NStr("vi = 'Ví dụ truy cập đến mục tin bổ sung của nguồn';
									|ru = 'Пример обращения к дополнительным реквизитам источника';
									|en = 'Example of accessing additional source attributes'; fa = 'Example of accessing additional source attributes';
									|it = 'Пример обращения к дополнительным реквизитам источника';
									|pl = 'Example of accessing additional source attributes';
									|tr = 'Ek kaynak özniteliklerine erişim örneği'"));
		ArrayInstructions.Add("</u></summary>");
		ArrayInstructions.Add("<blockquote><pre>");
		
		If TypeOfExpression = "ExportRule" And Not Parameters.ThisIsTable Then
			ExampleExpression =
				"For Everyone String From Parameters.Source.AdditionalAttributes Cycle
				|	If String.Property.IDForFormulas = ""IDOfAdditionalBankingDetails"" Then
				|		Parameters.Result = String.Value;
				|	EndIf;
				|EndOfTheCycle;";
			
		ElsIf TypeOfExpression = "ApplicabilityConditionOnExport"
				Or (TypeOfExpression = "ExportRule" And Parameters.ThisIsTable) Then
			ExampleExpression =
				"ValueOfAdditionalAttributes = Undefined;
				|For Everyone String From Parameters.Source.AdditionalAttributes Cycle
				|	If String.Property.IDForFormulas = ""IDOfAdditionalBankingDetails"" Then
				|		ValueOfAdditionalAttributes = String.Value;
				|	EndIf;
				|EndOfTheCycle;";
			
		ElsIf TypeOfExpression = "LoadingRule" And Not Parameters.ThisIsTable Then
			ExampleExpression =
				"For Everyone XDTOProperty From Parameters.Source.additionalProperties Cycle
				|	If XDTOProperty.objectID.ID = ""IDOfAdditionalBankingDetails"" Then
				|		Parameters.Result = XDTOProperty.propertySimpleValue;
				|	EndIf;
				|EndOfTheCycle;";
			
		ElsIf TypeOfExpression = "ApplicabilityConditionOnImport"
				Or (TypeOfExpression = "LoadingRule" And Parameters.ThisIsTable) Then
			ExampleExpression =
				"ValueOfAdditionalAttributes = Undefined;
				|For Everyone XDTOProperty From Parameters.Source.additionalProperties Cycle
				|	If XDTOProperty.objectID.ID = ""IDOfAdditionalBankingDetails"" Then
				|		ValueOfAdditionalAttributes = XDTOProperty.propertySimpleValue;
				|	EndIf;
				|EndOfTheCycle;";
			
		EndIf;
		ArrayInstructions.Add(StrReplace(ExampleExpression, "IDOfAdditionalBankingDetails", IDOfAdditionalBankingDetails));
		
		ArrayInstructions.Add("</pre></blockquote>");
		AddCollapsibleGroup(ArrayInstructions, False);
	EndIf;
	
	ArrayInstructions.Add("</body></html>");
	
	Instruction = StrConcat(ArrayInstructions);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DetailsWhenClicked(Item, EventData, StandardProcessing)
	
#If Not WebClient Then
	If ValueIsFilled(EventData.Button) And EventData.Button.tagName = "U" Then
		Return;
	EndIf;
	
	StandardProcessing = False;
#EndIf
	
	If Not ValueIsFilled(EventData.HRef) Then
		Return;
	EndIf;
	
	Position = StrFind(EventData.HRef, "#", SearchDirection.FromEnd);
	Ref = Mid(EventData.HRef, Position + 1);
	FormParameters = New Structure;
	FormParameters.Insert("Ref", Ref);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.WebServiceDescription",
		FormParameters, ThisObject,,,,, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Async Procedure TheCleanCommand(Val Command)
	
	QueryText = NStr("vi = 'Xóa biểu thức đã nhập?';
					|ru = 'Очистить введенное выражение?';
					|en = 'Clear the expression entered?'; fa = 'Clear the expression entered?';
					|it = 'Cancellare l''espressione inserita?';
					|pl = 'Wyczyścić wprowadzone wyrażenie?';
					|tr = '​​Girilen ifade temizlensin mi?'");
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(QueryText);
	
	If Response = DialogReturnCode.Yes Then
		Close("");
	EndIf;
	
EndProcedure

&AtClient
Procedure OkCommand(Command)
	
	Close(ComputedExpression);
	
EndProcedure

&AtClient
Procedure CheckCommand(Command)
	
	ClearMessages();
	CheckExpressionInEmbeddedLanguage(TypeOfExpression, ComputedExpression, ObjectTypeDM, ObjectTypeIS);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure PrintAttributeNameBEFORE(ArrayInstructions, AttributeStructure, AttributeName)
	
	If TypeOf(AttributeStructure.Type) = Type("ValueList")
				And AttributeStructure.Type.Count() > 0
				And Left(AttributeStructure.Type[0], 2) = "DM" Then
			ArrayInstructions.Add("<td><a href=""#");
			ArrayInstructions.Add(AttributeStructure.Type[0]);
			ArrayInstructions.Add(""">");
			ArrayInstructions.Add(AttributeName);
			ArrayInstructions.Add("</a></td>");
		Else
			ArrayInstructions.Add("<td>");
			ArrayInstructions.Add(AttributeName);
			ArrayInstructions.Add("</td>");
		EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddCollapsibleGroup(ArrayInstructions, StartTag)
	
	If Common.IsLinuxClient() Then
		Return;
	EndIf;
	
	If StartTag Then
		ArrayInstructions.Add("<details>");
	Else
		ArrayInstructions.Add("</details>");
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CheckExpressionInEmbeddedLanguage(TypeOfExpression, ComputedExpression, ObjectTypeDM, ObjectTypeIS)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = IntegrationWith1CDocumentManagementCore.NewObjectBefore(Proxy, ObjectTypeDM);
	ObjectIS = IntegrationWith1CDocumentManagementCore.NewIPObject(ObjectTypeIS);
	
	If TypeOfExpression = "ExportRule" Then
		Catalogs.RulesForIntegrationWith1CDocumentManagement.CheckUploadRuleExpression(
			ComputedExpression,
			ObjectIS);
		
	ElsIf TypeOfExpression = "ApplicabilityConditionOnExport" Then
		Catalogs.RulesForIntegrationWith1CDocumentManagement.CheckApplicabilityConditionExpressionWhenUploading(
			ComputedExpression,
			ObjectIS);
		
	ElsIf TypeOfExpression = "LoadingRule" Then
		Catalogs.RulesForIntegrationWith1CDocumentManagement.CheckLoadingRuleExpression(
			ComputedExpression,
			XDTODataObject,
			ObjectIS);
		
	ElsIf TypeOfExpression = "ApplicabilityConditionOnImport" Then
		Catalogs.RulesForIntegrationWith1CDocumentManagement.CheckApplicabilityConditionExpressionWhenLoading(
			ComputedExpression,
			XDTODataObject);
		
	EndIf;
	
	Common.MessageToUser(NStr("vi = 'Không tìm thấy lỗi';
								|ru = 'Ошибок не обнаружено';
								|en = 'No errors detected'; fa = 'No errors detected';
								|it = 'Non sono stati rilevati errori';
								|pl = 'Nie wykryto błędów';
								|tr = 'Hatalar algılanmıyor'"));
	
EndProcedure

#EndRegion
