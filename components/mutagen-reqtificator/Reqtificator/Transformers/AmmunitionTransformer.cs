﻿using Mutagen.Bethesda;
using Mutagen.Bethesda.Skyrim;

namespace Reqtificator.Transformers
{
    public class AmmunitionTransformer: Transformer<Ammunition, IAmmunitionGetter>
    {

        protected override bool ShouldProcess(IAmmunitionGetter record)
        {
            var keywordCheck = (!record.Keywords?.Contains(StaticReferences.Keywords.AlreadyReqtified) ?? true) &&
                               (!record.Keywords?.Contains(StaticReferences.Keywords.NoDamageRescaling) ?? true);
            return keywordCheck && record.Damage > 0.0f;
        }

        protected override void Process(Ammunition record)
        {
            record.Damage *= 4;
        }
    }
}