﻿using System.Collections.Generic;
using FluentAssertions;
using Hocon;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Skyrim;
using Reqtificator.Transformers.Rules;
using Reqtificator.Transformers.Rules.Conditions;
using Xunit;

namespace ReqtificatorTest.Transformers.Rules
{
    public class KeywordAssignmentRuleTest
    {
        [Fact]
        public void Should_parse_a_valid_config_file_into_a_rule()
        {
            var rawConfig = HoconConfigurationFactory.ParseString(@"
                feature_foo {
                    keywords_all = [ ""123456:Skyrim.esm"" ]
                    some_node {
                        keywords_all = [ ""123ABC:Skyrim.esm"" ]
                        keywords_assign = [ ""ABC123:Assign.esp"" ]
                    }
                    other_node {
                        keywords_all = [ ""123DEF:Skyrim.esm"" ]
                        keywords_assign = [ ""DEF123:Assign.esp"" ]
                    }
                }");

            var node1 = new KeywordAssignmentRule<INpcGetter>(
                assignments: new HashSet<IFormLinkGetter<IKeywordGetter>>
                    {new FormLink<IKeywordGetter>(FormKey.Factory("ABC123:Assign.esp"))},
                conditions: new HashSet<IAssignmentCondition<INpcGetter>>
                {
                    new HasAllKeywords<INpcGetter>(new HashSet<IFormLinkGetter<IKeywordGetter>>
                        {new FormLink<IKeywordGetter>(FormKey.Factory("123ABC:Skyrim.esm"))})
                },
                nodeName: "some_node",
                subNodes: new HashSet<AssignmentRule<INpcGetter, IKeywordGetter>>()
            );
            var node2 = new KeywordAssignmentRule<INpcGetter>(
                assignments: new HashSet<IFormLinkGetter<IKeywordGetter>>
                    {new FormLink<IKeywordGetter>(FormKey.Factory("DEF123:Assign.esp"))},
                conditions: new HashSet<IAssignmentCondition<INpcGetter>>
                {
                    new HasAllKeywords<INpcGetter>(new HashSet<IFormLinkGetter<IKeywordGetter>>
                        {new FormLink<IKeywordGetter>(FormKey.Factory("123DEF:Skyrim.esm"))})
                },
                nodeName: "other_node",
                subNodes: new HashSet<AssignmentRule<INpcGetter, IKeywordGetter>>()
            );
            var expected = new KeywordAssignmentRule<INpcGetter>(
                assignments: new HashSet<IFormLinkGetter<IKeywordGetter>>(),
                conditions: new HashSet<IAssignmentCondition<INpcGetter>>
                {
                    new HasAllKeywords<INpcGetter>(new HashSet<IFormLinkGetter<IKeywordGetter>>
                        {new FormLink<IKeywordGetter>(FormKey.Factory("123456:Skyrim.esm"))})
                },
                nodeName: "feature_foo",
                subNodes: new HashSet<AssignmentRule<INpcGetter, IKeywordGetter>> { node1, node2 }
            );

            var result = KeywordAssignmentRule.LoadFromConfigurationFile<INpcGetter>(rawConfig);

            result.Should().HaveCount(1);
            result[0].Should().BeEquivalentTo(expected);
        }
    }
}