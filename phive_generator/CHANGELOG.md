## 0.3.0
- added true classhooks

## 0.2.0

- Added `@PHiveAutoType` support: `PhiveAutoTypeGenerator`, `TypeIdRegistry`, and `assign_type_ids` CLI for registry-driven typeId assignment.
- Refactored `PhiveGenerator` into shared components (`annotation_helpers`, `field_collection`, `router_collection`, `adapter_emitter`) consumed by both generators.
- See 0.1.0 for base adapter and router descriptor generation.

## 0.1.0

- Initial generator release for PHive adapters.
- Added merged model and field hook pipeline generation.
- Added `autoFields` support for constructor-ordered field inference.
- Added generated router descriptors from `@PHivePrimaryKey` and `@PHiveRef`.
