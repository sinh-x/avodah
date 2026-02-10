/// CRDT (Conflict-free Replicated Data Types) primitives for Avodah.
///
/// This library provides the building blocks for distributed, offline-first
/// data synchronization:
///
/// - [HybridLogicalClock] / [HybridTimestamp]: Distributed event ordering
/// - [LWWRegister] / [LWWMap]: Last-Writer-Wins value storage
/// - [LWWSet]: Last-Writer-Wins element set
/// - [GCounter] / [PNCounter]: Distributed counters
///
/// These primitives can be composed to build higher-level CRDT documents
/// that automatically merge without conflicts.
library;

export 'hlc.dart';
export 'lww_register.dart';
export 'lww_set.dart';
export 'g_counter.dart';
export 'crdt_document.dart';
